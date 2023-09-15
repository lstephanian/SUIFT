// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

// based in part on https://docs.soliditylang.org/en/v0.8.3/solidity-by-example.html#blind-auction
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/IERC1155Receiver.sol";
import { Tickets } from './Tickets.sol';
import "../libraries/Suave.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is ERC1155Holder, Ownable {
    //this is a list of event goers that, post-auction end, you'd otherwise get from an oracle
    //here, we will create a list of one address for examples sake and the contract will only know this address attended the event
    mapping(address  => bool) private attendees;
    uint public immutable TICKET_ADDRESS;
    uint public immutable AUCTION_START_TIME;
    uint public immutable AUCTION_END_TIME;
    uint public immutable REBATE_END_TIME;
    uint public immutable TICKET_RESERVE_PRICE;
    uint public immutable TICKET_SUPPLY;
    uint public immutable AUCTION_TICKETS_TYPE; 
    bool public ended = false;
    uint private capitalSpentInAuction = 0;
    bool public attended = false;
    struct Bid{
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
    }

    //list of bids we get
    Bid[] private bids;
    mapping(address beneficiary => uint256 refund) private bidRefunds;
    //list of winners and their bid
    mapping(address winner => uint winningBid) private winners;

    event BidEntered(address indexed beneficiary, uint256 indexed amount);
    event BitRefundReceived(address indexed beneficiary, uint256 indexed amount);

    // Events that will be emitted on changes.
    event AuctionCreated(address ticketsAddress, uint ticketId, uint startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice);
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(mapping winners);
    
    constructor(address _ticketsAddress, uint _auctionTicketsId, uint _startTime, uint _biddingLength, uint _rebateLength, uint _ticketSupply, uint _ticketReservePrice) {
        require(_startTime > 0, 'Must provide start time');
        require(_biddingLength > 0, 'Must provide bidding length');
        require(_rebateLength > 0, 'Must provide rebate length');
        require(_ticketSupply > 0, 'Must provide supply');
        require(_ticketReservePrice > 0, 'Must provide reserve price');
        
        AUCTION_TICKETS_TYPE = _auctionTicketsId;
        AUCTION_START_TIME = _startTime;
        AUCTION_END_TIME = _startTime + _biddingLength;
        REBATE_END_TIME = AUCTION_END_TIME + _rebateLength;
        TICKET_SUPPLY = _ticketSupply;
        TICKET_RESERVE_PRICE = _ticketReservePrice;
        TICKET_ADDRESS = _ticketsAddress;

        //mint the specific 1155 tickets
        Tickets tickets = Tickets(_ticketsAddress);
        tickets.mint(_auctionTicketsId, _ticketSupply);

        //emit event
        emit AuctionCreated(_ticketsAddress, _auctionTicketsId, _startTime, _biddingLength, _rebateLength, _ticketSupply, _ticketReservePrice);
    }
    
    //Note: block.timestamp could be manipulated
    function bid() external payable {
        require(Suave.isConfidential());
        require(block.timestamp >= AUCTION_START_TIME, "The auction is not yet active");
        require(block.timestamp <= AUCTION_END_TIME, "The auction has ended");
        require(ended == false, "The auction has ended");
        require(msg.value >= TICKET_RESERVE_PRICE, "The bid cannot be lower than ticket value");

        uint minBidIndex = _minBidIndex();

        require(msg.value > minBidIndex, 'Your bid lower than the minimum');
        
        //create a bid struct: beneficiary, bid amount, time of bid
        Bid memory bid = Bid(payable(msg.sender), msg.value, block.timestamp); 

        //check whether number of bids is less than total ticket supply
        if (TICKET_SUPPLY > bids.length) {
            
            //add bid to bid struct and bidder to winner map
            //TODO: send this to confidential store - not sure if doing this right
		    bytes memory bundleData = this.fetchBidConfidentialBundleData();
            Suave.Bid memory suaveBid = Suave.newBid(decryptionCondition, bidAllowedPeekers, "suift:v0:eventbids");
            Suave.confidentialStoreStore(suaveBid.id, "suift:v0:eventbids", bundleData);

            //push the bid to the bids array
            bids.push(bid);

            //emit event indicating a bid has been placed
            emit BidEntered(msg.sender, msg.value);

            return;
        }
        _replaceLowestBid(bid, minBidIndex);
    }

    //Enable withdrawals for bids that have been overbid
    function withdrawOverbid() external returns (bool) {
        uint256 amount = bidRefunds[msg.sender];
        require(amount != 0, 'Nothing to withdraw');

        bidRefunds[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{ value: amount }('');
        require(success);

        return(success);
        emit BitRefundReceived(msg.sender, amount);
    }


    /// End the auction (in case you need to early)
    function auctionEnd() public onlyOwner {
        require(block.timestamp >= AUCTION_END_TIME, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        // emit AuctionEnded(mapping winners);

        //iterate though bids and transfer a single token to each winner
        for (uint i = 0 ; i < bids.length; i++){
                safeTransferFrom(this.address, TICKET_ADDRESS, AUCTION_TICKETS_TYPE, 1, "");
            }
        } 
    }

    function _isAuctionActive() internal view returns (bool) {
        return ended == false || block.timestamp > AUCTION_START_TIME && block.timestamp < AUCTION_END_TIME;
    }

    //replaces one of the lowest accepted bids in the auction with this latest bid and adds a refund to the beneficiary who was overbid
    //Note: this could be improved by looping through timestamps and determining who was the most recent lowest bid
    function _replaceLowestBid(Bid memory bid, uint256 minBidIndex) internal {
        Bid memory currentBid = bids[minBidIndex];
        bidRefunds[currentBid.beneficiary] += currentBid.amount;
        currentBid = bid;
    }

    //loops through index of bids and if the bid amount is greater than the minimum bid amount, then add it to the bidindex
    function _minBidIndex() internal view returns (uint256 minIndex) {
        uint minAmount;
        for(uint256 i; i < bids.length; i++) {
            Bid memory bid = bids[i];

            if (bid.amount < minAmount || minAmount == 0) {
                    minIndex = i;
                    minAmount = bid.amount;
            }
        }
    }

    function _wonAuction(address participant) private view returns(bool){   

        // TODO: retrieve in confidential data store
        // Suave.BidId[] memory mergedBidIds = abi.decode(Suave.confidentialStoreRetrieve(allShareMatchBids[j].id, "mevshare:v0:mergedBids"), (Suave.BidId[]));

        if(ended == true){
            if(winners[participant] != 0){
                return(true);
            }
            else{
                return(false);
            }
        }
    }

    function setterAttendConcert(address _participant) public onlyOwner {
        attendees.push(_participant);
    }
    function _getterAttendedConcert(address participant) private view returns(bool) {
        return(attendees[participant]);
    }

    function _isRebatePeriod() private view returns(bool){
        return ended && block.timestamp <= REBATE_END_TIME;
    }
    
    //Enable withdrawals for bids that have been overbid
    function rebateWithdraw() external returns (bool) {
        require(_isRebatePeriod(), "It's not rebate period");
        require(_attendedConcert(msg.sender), "You did not attend the event");

        bytes32 encodedAddy = keccak256(abi.encode(bids.beneficiary));
        for (uint i = 0 ; i < bids.length; i++){
            if (encodedAddy == keccak256(abi.encode(msg.sender))){
                uint amtPaid = bids[i].amount;
            }
        } 

        //calculate how much rebate participants get
        uint delta = amtPaid - TICKET_RESERVE_PRICE;

        (bool success,) = payable(msg.sender).call{ value: delta }('');
        require(success);

        return(success);
        emit BitRefundReceived(msg.sender, delta);        
    }
    
    function burnRebate(address participant) private onlyOwner {
        require(_isRebatePeriod(), "It's not rebate period");
        require(_attendedConcert(participant), "You did not attend the event");

        bytes32 encodedAddy = keccak256(abi.encode(bids.beneficiary));
        for (uint i = 0 ; i < bids.length; i++){
            if (encodedAddy == keccak256(abi.encode(msg.sender))){
                uint burnAmt = bids[i].amount;
            }
        } 

        //setting money on fire, fun
        address burnAddy = 0x000000000000000000000000000000000000dEaD;

        (bool sent,) = burnAddy.call{value: burnAmt}("");
        require(sent, "Failed to send Ether");
    }
}

