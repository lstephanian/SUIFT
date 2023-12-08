// SPDX-License-Identifier: UNLICENSED
// author: @lstephanian

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../suave-geth/suave/sol/libraries/Suave.sol";
import { Tickets } from './Tickets.sol';

contract Auction is ERC1155Holder, Ownable {
    address [] winners;
    mapping(address => bool) private purchasers;
    mapping(address  => bool) private attendees;
    address public immutable TICKET_ADDRESS;
    uint public immutable TICKET_RESERVE_PRICE;
    uint public immutable TICKET_SUPPLY;
    uint public immutable AUCTION_TICKETS_TYPE; 
    address public immutable CHARITY_ADDRESS;
    uint private immutable DECRYPTION_CONDITION;
    bool public auctionEnded = false;
    uint private capitalSpentInAuction = 0;
    bool public attended = false;
    uint public ticketSold = 0;
    string bidType;
    address [] addressList;
    struct AuctionBid {
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
    }
    AuctionBid[] private bids;

    // Events
    event BidEntered(address indexed beneficiary, uint256 indexed amount);
    event BitRefundReceived(address indexed beneficiary, uint256 indexed amount);
    event MinBidUpdated(uint256 indexed amount);
    event AuctionEnded(bool);
    event AuctionCreated(address ticketsAddress, uint auctionTicketsId, uint ticketSupply, uint ticketReservePrice, address charity);
    event AttendedEvent(address eventgoer);
    event CycledPaymentPeriod(bool);

    constructor (address _ticketsAddress, uint _auctionTicketsId, uint _ticketSupply, uint _ticketReservePrice, address _charity, address _address) {
        require(_auctionTicketsId == 1 || _auctionTicketsId == 2 || _auctionTicketsId == 3, "Token does not exist");
        require(_ticketSupply > 0, 'Must provide supply');
        require(_ticketReservePrice > 0, 'Must provide reserve price');
        
        CHARITY_ADDRESS = _charity;
        AUCTION_TICKETS_TYPE = _auctionTicketsId;
        TICKET_SUPPLY = _ticketSupply;
        TICKET_RESERVE_PRICE = _ticketReservePrice;
        TICKET_ADDRESS = _ticketsAddress;
        DECRYPTION_CONDITION = _decryptionCondition;
        addressList.push(_address);

        //emit event
        emit AuctionCreated(_ticketsAddress, _auctionTicketsId, _ticketSupply, _ticketReservePrice, _charity);
    }
    
    // Internal function to save order details
    function _sendBidToConfidentialStore(AuctionBid _bid) internal view {
        address[] memory allowedList = new address[](1);
        allowedList[0] = address(this);

        Suave.Bid memory bid = Suave.newBid(
            10,
            allowedList,
            allowedList,
            "auctionBid"
        );

        Suave.confidentialStore(bid.id, "auctionBid", abi.encode(_bid));
    }
    
    function _retrieveBid(uint id) public onlyOwner returns(string) {
        bytes memory value = Suave.confidentialRetrieve(bid.id, "auctionBid");
        require(keccak256(value) == keccak256(abi.encode(1)));

        Suave.Bid[] memory allShareMatchBids = Suave.fetchBids(10, "auctionBid");
        return abi.encodeWithSelector(this.callback.selector);
    }

    function sendBid(uint _bidAmount) public {
        require(auctionEnded == false, "The auction has ended");
        require(msg.value >= TICKET_RESERVE_PRICE, "The bid cannot be lower than ticket value");

        (uint minBidIndex, uint minAmount) = _minBidIndex();

        AuctionBid auctionBid = new AuctionBid(msg.sender, _bidAmount, block.timestamp);

        //check whether number of bids is less than total ticket supply
        if (TICKET_SUPPLY > bids.length) {
            
            _sendBidToConfidentialStore(auctionBid);
            bids.push(auctionBid);

            emit BidEntered(msg.sender, msg.value);
            return;
        }
        require(msg.value >= minAmount, 'Your bid is lower than the minimum');
        _replaceLowestBid(auctionBid, minBidIndex);
    }

    // End the auction
    function auctionEnd() public onlyOwner {
        auctionEnded = true;
        emit AuctionEnded(auctionEnded);

        //determine winners
        // from confidential store

        //emit winners
    }

    function payForTickets() public payable {
        //todo: require that msg.sender address is on the list of winners, otherwise revert
        //require that auction is ended
        //mint tickets to msg.sender
    }

    // owner must call this repeatedly until there are no more tickets to sell
    function cyclePaymentPeriod() public onlyOwner {
        require(auctionEnded, "auction ongoing");
        require(TICKET_SUPPLY > ticketSold, "no more tickets to sell");
        //diff purchasers_array.length - ticket_supply

        uint leftover = TICKET_SUPPLY - ticketsSold;
        uint x;

        //remove winners who didn't pay from winner array

        
        //add that number of next in line addresses


        // find the next x amount of highest bidders and allow them to pay

        emit CycledPaymentPeriod(true);
        //emit new winners
    }

    function _isAuctionActive() internal view returns (bool) {
        return(auctionEnded==false);
    }

    //replaces one of the lowest accepted bids in the auction with this latest bid and adds a refund to the beneficiary who was overbid
    //Note: this could be improved by looping through timestamps and determining who was the most recent lowest bid
    function _replaceLowestBid(Bid memory bid, uint256 minBidIndex) internal {
        Bid memory currentBid = bids[minBidIndex];
        bidRefunds[currentBid.beneficiary] += currentBid.amount;
        currentBid = bid;
        emit MinBidUpdated(currentBid.amount);
    }

    //loops through index of bids and if the bid amount is greater than the minimum bid amount, then add it to the bidIndex
    function _minBidIndex() internal view returns (uint minIndex,  uint minAmount) {
       for(uint256 i; i < bids.length; i++) {
            Bid memory newBid = bids[i];

            if (newBid.amount < minAmount || minAmount == 0) {
                    minIndex = i;
                    minAmount = newBid.amount;
            }
        }
    }

    function setAttendConcert(address _participant) public onlyOwner {
        // require auction is over
        // require participant on list of winners -- reduce shadiness from owners!!
        attendees[_participant] = true;
        emit AttendedEvent(_participant);
    }

    function _getterAttendedConcert(address participant) private view returns(bool) {
        return(attendees[participant]);
    }

    //Enable withdrawals for bids that have been overbid
    //todo; double check, do we need this??? or can we just send the amount back 
    function rebateWithdraw() external returns (bool) {
        require(_isRebatePeriod(), "It's not rebate period");
        require(_getterAttendedConcert(msg.sender), "You did not attend the event");
        require(rebateWithdrawn[msg.sender] == false, "You have already withdrawn your rebate");

        uint amtPaid;

        for (uint i = 0 ; i < bids.length; i++){
            bytes32 encodedAddy = keccak256(abi.encode(bids[i].beneficiary));

            if (encodedAddy == keccak256(abi.encode(msg.sender))){
                amtPaid = bids[i].amount;
            }
        } 

        //calculate how much rebate participants get
        uint delta = amtPaid - TICKET_RESERVE_PRICE;

        //mark the rebate as withdrawn and send rebate
        rebateWithdrawn[msg.sender] = true;
        (bool success,) = payable(msg.sender).call{ value: delta }('');
        emit BitRefundReceived(msg.sender, delta);        

        require(success);
        return(success);
    }
    
    //after the rebate period is over, the owner will call burn rebate, burning the eth of those who did not attend the event
    //assume owner has a list of those who purcahsed tickets and did not attend 
    function sendRebate(address participant) public onlyOwner {
        require(_isRebatePeriod() == false || _isAuctionActive() == false, "Rebate period is not over yet");
        require(rebateWithdrawn[participant] == false, "Participant already withdrew their rebate");
        require(rebateBurned[participant] == false, "Participant already had their rebate burned");
        uint burnAmt;

        for (uint i = 0 ; i < bids.length; i++){
            bytes32 encodedAddy = keccak256(abi.encode(bids[i].beneficiary));

            if (encodedAddy == keccak256(abi.encode(msg.sender))){
                burnAmt = bids[i].amount;
            }
        } 

        //mark as burned
        rebateBurned[participant] = true;

        (bool sent,) = CHARITY_ADDRESS.call{value: burnAmt}("");
        require(sent, "Failed to send Ether");
    }
}