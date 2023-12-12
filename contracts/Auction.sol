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
    mapping(address => bool) private attendees;
    mapping(address => uint) private accountForWithdrawals;
    mapping(address => uint) private boosted;
    address public immutable TICKET_ADDRESS;
    uint public immutable TICKET_RESERVE_PRICE;
    uint public immutable TICKET_SUPPLY;
    uint public immutable AUCTION_TICKETS_TYPE; 
    address public immutable CHARITY_ADDRESS;
    uint private immutable DECRYPTION_CONDITION  = 10;
    uint private currMinBid;
    bool public auctionEnded = false;
    bool public rebatePeriodEnded = false;
    struct AuctionBid {
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
    }
    AuctionBid[] private bids;
    AuctionBid[] private winningBids;

    Tickets tickets = new Tickets();

    // Events
    event BidEntered(address indexed beneficiary, uint256 indexed amount);
    event BitRefundReceived(address indexed beneficiary, uint256 indexed amount);
    event MinBidUpdated(uint256 indexed amount);
    event AuctionEnded(bool);
    event AuctionCreated(address ticketsAddress, uint auctionTicketsId, uint ticketSupply, uint ticketReservePrice, address charity);
    event AttendedEvent(address eventgoer);
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

        //emit event
        emit AuctionCreated(_ticketsAddress, _auctionTicketsId, _ticketSupply, _ticketReservePrice, _charity);
    }

    // taylor swift can graciously identify certain superfans to "boost" i.e. give them an additional amount of cash to boost their bid higher
    function setBoosted(address _bidder, uint boostAmount) public onlyOwner {
        require(boostAmount > 0, "boost amount must be greater than 0");
        boosted[_bidder] = boostAmount;
    }

    function _getBoosted(address _bidder) private onlyOwner returns (uint) {
        return(boosted[_bidder]);
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

        // check if bidder got a boost from the owner
        // if so, boost their bid
        if (_getBoosted(msg.sender) > 0) {
            _bidAmount += _getBoosted(msg.sender);
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
        
        // mint tickets to msg.sender
        tickets.mint(msg.sender, AUCTION_TICKETS_TYPE, 1);
    }

    function setAttendConcert(address _participant) public onlyOwner {
        require(auctionEnded, "Auction still ongoing");
        require(_checkIfWinner(_participant), "Did not win tickets");

        attendees[_participant] = true;
        emit AttendedEvent(_participant);

        // allow particpant to now withdraw rebate - add rebate to their "account"
        for (uint i = 0; i < bids.length; i++) {
            if (bids[i].beneficiary == _participant) {
                accountForWithdrawals[bids[i].beneficiary] += bids[i].amount;
            }
        }
    }

    //Enable withdrawals for bids that have been overbid
    function rebateWithdraw() external returns (bool) {
        require(rebatePeriodEnded == false, "It's not rebate period");
        require(_getAttendedConcert(msg.sender), "You did not attend the event");
        require(accountForWithdrawals[msg.sender] > 0, "Nothing to withdraw");

        uint amountAvailable = accountForWithdrawals[msg.sender];

        //mark the rebate as withdrawn and send rebate
        (bool success,) = payable(msg.sender).call{ value: amountAvailable }('');
        emit BitRefundReceived(msg.sender, amountAvailable);        
        return(success);
    }
    
    //after the rebate period is over, the owner will call burnOrSendRebate, burning the eth of those who did not attend the event or sending it to charity
    //assume owner has a list of those who purchased tickets and did not attend 
    function burnOrSendRebate(address participant) public onlyOwner {
        require(rebatePeriodEnded && auctionEnded, "Rebate period is not over yet");

        uint burnAmt;

        for (uint i = 0 ; i < bids.length; i++){
            bytes32 encodedAddy = keccak256(abi.encode(bids[i].beneficiary));

            if (encodedAddy == keccak256(abi.encode(msg.sender))){
                burnAmt = accountForWithdrawals[participant];
                (bool sent,) = CHARITY_ADDRESS.call{value: burnAmt}("");
                require(sent, "Failed to send Ether");
            }
        } 
    }
    
    // Internal function to save order details confidentially
    function _sendBidToConfidentialStore(AuctionBid _bid) internal view {
        //allowing this contract to be a "peeker" into the confidential store
        address[] memory allowedList = new address[](1);
        allowedList[0] = 0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829; // wildcard address so any kettle can access

        // initialize confidential store
        Suave.Bid memory bid = Suave.newBid(DECRYPTION_CONDITION, allowedList, allowedList, "auctionBid");

        // save bid in confidential store
        Suave.confidentialStore(bid.id, "auctionBid", abi.encode(_bid));
    }

    function _getWinningBids() internal returns(AuctionBid []) {
        currMinBid = _getMinBid();

        // extract bids from confidential store
        for (uint i = 0; i < Suave.bidIds.length; i++) {
            uint bidVal = (Suave.confidentialRetrieve(bid[i], "auctionBid")).amount;

            // only collecting bids that have won
            // todo: sort by timestamp and only include ticket_supply number of bids
            if (bidVal >= currMinBid) {
                bids[i] = Suave.confidentialRetrieve(bid[i], "auctionBid");
            }
            // if bids have lost, allow bidders to withdraw by adding to their withdrawal account
            if (bidVal < currMinBid) {
                accountForWithdrawals[bids[i].beneficiary] += bids[i].amount;
            }
        }
		return bids;
    }

    function _getAttendedConcert(address _participant) internal returns(bool) {
        return(attendees[_participant]);
    }

    function _checkIfWinner(address _bidder) internal returns (bool) {
        require(auctionEnded, "auction still ongoing");
        _getWinningBids();
        for (uint i=0; i < bids.length; i++){
            if (bids[i].beneficiary == _bidder) {
                return true;
            }
        }
        return false;
    }

    function _getAmountOwed(address _bidder) internal returns (uint) {
        require(auctionEnded, "auction still ongoing");
        _getWinningBids();
        for (uint i=0; i < bids.length; i++){
            if (bids[i].beneficiary == _bidder) {
                return bids[i].amount;
            }
        }
    }
    
    function _getMinBid() internal returns(uint) {
        (uint left, uint i) = allBidValues[0];
        (uint right, uint j) = allBidValues[allBidValues.length - 1];
        
        if (i == j) return;
        uint pivot = bids[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (bids[uint(i)] > pivot) i++;
            while (pivot > bids[uint(j)]) j--;
            if (i <= j) {
                (bids[uint(i)], bids[uint(j)]) = (bids[uint(j)], bids[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) {
            _getMinBid(bids, left, j);
        }

        if (i < right) {
            _getMinBid(bids, i, right);
        }

        return(allBidValues[TICKET_SUPPLY-1]);
    }
}