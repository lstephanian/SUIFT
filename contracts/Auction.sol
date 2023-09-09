// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

// based in part on https://docs.soliditylang.org/en/v0.8.3/solidity-by-example.html#blind-auction
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { Tickets } from './Tickets.sol';
import "../libraries/Suave.sol";

contract Auction is ERC1155Holder {
    //this is a list of event goers that, post-auction end, you'd otherwise get from an oracle
    //here, we will create a list of one address for examples sake and the contract will only know this address attended the event
    mapping(address  => bool) private attendeeOracle;

    address public immutable TICKETS_ADDRESS = 0x55eBc20b2c938cfccfFEe1707B7604fB3C8703E0; //right now this is me
    uint public immutable AUCTION_START_TIME;
    uint public immutable AUCTION_END_TIME;
    uint public immutable REBATE_END_TIME;
    uint public immutable TICKET_RESERVE_PRICE;
    uint public immutable TICKET_SUPPLY;
    uint public immutable AUCTION_TICKETS_TYPE; 
    bool public ended;
    uint capitalSpentInAuction;
    bool attended = false;
    address owner; 
    struct Bid{
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
    }

    Bid[] private bids;
    mapping(address beneficiary => uint256 refund) private bidRefunds;
    mapping(address winner => uint winningBid) private winners;

    event BidEntered(address indexed beneficiary, uint256 indexed amount);
    event BitRefundReceived(address indexed beneficiary, uint256 indexed amount);

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    constructor(uint _auctionTicketsId, uint _startTime, uint _biddingLength, uint _rebateLength, uint _ticketSupply, uint _ticketReservePrice) 
    {
        require(_startTime > 0, 'Must provide start time');
        require(_biddingLength > 0, 'Must provide bidding length');
        require(_rebateLength > 0, 'Must provide rebate length');
        require(_ticketSupply > 0, 'Must provide supply');
        require(_ticketReservePrice > 0, 'Must provide reserve price');
        

        owner = msg.sender;
        AUCTION_TICKETS_TYPE = _auctionTicketsId;
        AUCTION_START_TIME = _startTime;
        AUCTION_END_TIME = _startTime + _biddingLength;
        REBATE_END_TIME = AUCTION_END_TIME + _rebateLength;
        TICKET_SUPPLY = _ticketSupply;
        TICKET_RESERVE_PRICE = _ticketReservePrice;

        //mint the specific 1155 tickets
        Tickets tickets = Tickets(TICKETS_ADDRESS);
        tickets.mint(_auctionTicketsId, _ticketSupply);

        //adding msg.sender to the event attendee list
        attendeeOracle[msg.sender] = true;
    }
    
    //Note: block.timestamp could be manipulated
    function bid() external payable {
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
            bids.push(bid);
            winners[msg.sender] = msg.value;

            //emit event indicating a bid has been placed
            // emit BidEntered(msg.sender, msg.value);
            // emit MinBidIncreased(msg.sender, msg.value);

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
        // emit BitRefundReceived(msg.sender, amount);
    }


    /// End the auction (in case you need to early)
    function auctionEnd() public {
        require(msg.sender == owner, "You need to be the owner of the contract to do this");
        require(block.timestamp >= AUCTION_END_TIME, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        // emit AuctionEnded();

        //TODO: Send 1155 NFTs to winners
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
        
        //add address of this bid to the winners list
        winners[currentBid.beneficiary] = currentBid.amount;

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

    function _wonAuction(address participant) private returns(bool){
        require(_isAuctionActive() == false, "Auction still ongoing");
        require(block.timestamp >= AUCTION_START_TIME, "The auction is not yet active");   
        if(winners[participant] != 0){
            return(true);
        }
    }

    function _attendedConcert(address participant) private returns(bool) {
        require(_isAuctionActive() == false, "Auction still ongoing");
        require(block.timestamp >= AUCTION_START_TIME, "The auction is not yet active");
        require(_wonAuction(participant), "Participant did not win Auction");
        if(attendeeOracle[msg.sender]){
            return(true);
        }
    }

    function _isRebatePeriod() private returns(bool){
        require(_isAuctionActive() == false, "Auction still ongoing");
        require(block.timestamp >= AUCTION_START_TIME, "The auction is not yet active");
        
        if(block.timestamp <= REBATE_END_TIME && block.timestamp >= AUCTION_END_TIME) {
            return(true);
        }
    }
    
    //Enable withdrawals for bids that have been overbid
    function rebateWithdraw() external returns (bool) {
        require(_isRebatePeriod(), "It's not rebate period");
        require(_attendedConcert(msg.sender), "You did not attend the event");


        //calculate how much rebate participants get
        uint delta = winners[msg.sender] - TICKET_RESERVE_PRICE;

        (bool success,) = payable(msg.sender).call{ value: delta }('');
        require(success);

        return(success);
        // emit BitRefundReceived(msg.sender, delta);        
    }
    
    function burnRebate(address participant) private{
        require(msg.sender == owner, "You need to be the owner of the contract to do this");
        require(_isRebatePeriod(), "It's not rebate period");
        require(_attendedConcert(participant), "You did not attend the event");

        uint burnAmt = winners[participant];
        address burnAddy = 0x000000000000000000000000000000000000dEaD;

        (bool sent, bytes memory data) = burnAddy.call{value: burnAmt}("");
        require(sent, "Failed to send Ether");
    }
}

