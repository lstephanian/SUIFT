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
    address [] bidders;
    uint [] allBidValues;
    mapping(address => bool) private purchasers;
    mapping(address  => bool) private attendees;
    address public immutable TICKET_ADDRESS;
    uint public immutable TICKET_RESERVE_PRICE;
    uint public immutable TICKET_SUPPLY;
    uint public immutable AUCTION_TICKETS_TYPE; 
    address public immutable CHARITY_ADDRESS;
    uint private immutable DECRYPTION_CONDITION;
    uint private currMinBid;
    bool public auctionEnded = false;
    uint private capitalSpentInAuction = 0;
    bool public attended = false;
    uint public ticketSold = 0;
    string bidType;
    struct AuctionBid {
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
    }
    AuctionBid[] private bids;
    AuctionBid[] private winningBids;

    // Events
    event BidEntered(address indexed beneficiary, uint256 indexed amount);
    event BitRefundReceived(address indexed beneficiary, uint256 indexed amount);
    event MinBidUpdated(uint256 indexed amount);
    event AuctionEnded(bool);
    event AuctionCreated(address ticketsAddress, uint auctionTicketsId, uint ticketSupply, uint ticketReservePrice, address charity);
    event AttendedEvent(address eventgoer);
    event CycledPaymentPeriod(bool);
    event AuctionEnded(address[] winners);

    constructor (address _ticketsAddress, uint _auctionTicketsId, uint _ticketSupply, uint _ticketReservePrice, address _charity) {
        require(_auctionTicketsId == 1 || _auctionTicketsId == 2 || _auctionTicketsId == 3, "Token does not exist");
        require(_ticketSupply > 0, 'Must provide supply');
        require(_ticketReservePrice > 0, 'Must provide reserve price');
        
        CHARITY_ADDRESS = _charity;
        AUCTION_TICKETS_TYPE = _auctionTicketsId;
        TICKET_SUPPLY = _ticketSupply;
        TICKET_RESERVE_PRICE = _ticketReservePrice;
        TICKET_ADDRESS = _ticketsAddress;
        DECRYPTION_CONDITION = _decryptionCondition;

        //emit event
        emit AuctionCreated(_ticketsAddress, _auctionTicketsId, _ticketSupply, _ticketReservePrice, _charity);
    }

    // bidders enter a "verbal" bid amount as well a deposit equal to the face value of the ticket
    // bidders can lose this deposit if they win and don't pay the delta between the this deposit and their verbal bid
    function sendBid(uint _bidAmount) public {
        require(auctionEnded == false, "The auction has ended");
        require(_bidAmount >= TICKET_RESERVE_PRICE, "The bid cannot be lower than ticket value");

        // if bidder hasn't previously bid, they need to pay ticket reserve amount
        // add them to the bidders list
        if (bidders[msg.sender] == false){
            require(msg.value == TICKET_RESERVE_PRICE, "Required to send ticket reserve amount");
            bidders.push(msg.sender);
        }

        // creates a new auction bid, which tracks bidder, their verbal amount, and the time of bid
        AuctionBid auctionBid = new AuctionBid(msg.sender, _bidAmount, block.timestamp);

        // send the bid to the confidential store and add bid amount to bid value array
        _sendBidToConfidentialStore(auctionBid);
        allBidValues.push(_bidAmount);

        uint latestMinBid = _getMinBid();
        if (currMinBid != latestMinBid){
            currMinBid = latestMinBid;
            emit MinBidUpdated(latestMinBid);
        }
    }
    
    // Owner can end the auction
    function auctionEnd() public onlyOwner {
        auctionEnded = true;
        emit AuctionEnded(auctionEnded);

        //determine winners and emit list
        winningBids = _getWinningBids();
        emit AuctionEnded(winningBids);
    }

    function payForTickets() public payable {
        require(auctionEnded, "Auction still ongoing");
        require(_checkIfWinner(msg.sender), "Did not win tickets");
        require(msg.value >= (_getAmountOwed(msg.sender) - TICKET_RESERVE_PRICE), "Payment amout incorrect");
        // TODO: mint msg.sender tickets
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

    function setAttendConcert(address _participant) public onlyOwner {
        require(auctionEnded, "Auction still ongoing");
        require(_checkIfWinner(_participant), "Did not win tickets");

        attendees[_participant] = true;
        emit AttendedEvent(_participant);
    }

    //Enable withdrawals for bids that have been overbid
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
    
    // Internal function to save order details confidentially
    function _sendBidToConfidentialStore(AuctionBid _bid) internal view {
        //allowing this contract to be a "peeker" into the confidential store
        address[] memory allowedList = new address[](1);
        allowedList[0] = address(this);

        // initialize confidential store
        Suave.Bid memory bid = Suave.newBid(DECRYPTION_CONDITION, allowedList, allowedList, "auctionBid");

        // save bid in confidential store
        Suave.confidentialStore(bid.id, "auctionBid", abi.encode(_bid));
    }

    function _getWinningBids() internal returns(AuctionBid []) {
        bytes memory value = Suave.confidentialRetrieve(bid.id, "auctionBid");
        require(keccak256(value) == keccak256(abi.encode(1)));

        uint currMinBid = _getMinBid();

        // extract bids from confidential store
        for (uint i = 0; i < bidIds.length; i++) {
            uint bidVal = (Suave.confidentialRetrieve(bidIds[i], "auctionBid")).amount;
            if (bidVal >= currMinBid) {
                bids[i] = Suave.confidentialRetrieve(bidIds[i], "auctionBid");
            }
        }
		return bids;
    }

    function _checkIfWinner(address _bidder) internal returns (bool) {
        require(auctionEnded, "auction still ongoing");
        _getWinningBids();
        for (uint i=0; i < bids.length; i++){
            if (bid.beneficiary == _bidder) {
                return true;
            }
        }
        return false;
    }

    function _getAmountOwed(address _bidder) internal returns (uint) {
        require(auctionEnded, "auction still ongoing");
        _getWinningBids();
        for (uint i=0; i < bids.length; i++){
            if (bid.beneficiary == _bidder) {
                return bid.amount;
            }
        }
    }
    
    function _getMinBid() internal returns(uint) {
        (uint left, uint i) = allBidValues[0];
        (uint right, uint j) = allBidValues[allBidValues.length - 1];
        
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] > pivot) i++;
            while (pivot > arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) {
            quickSort(arr, left, j);
        }

        if (i < right) {
            quickSort(arr, i, right);
        }

        return(allBidValues[TICKET_SUPPLY-1]);
    }
    
    function _getterAttendedConcert(address participant) private view returns(bool) {
        return(attendees[participant]);
    }    
}