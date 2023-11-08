// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { Tickets } from './Tickets.sol';
import "../libraries/Suave.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is ERC1155Holder, Ownable {
    mapping(address  => bool) private attendees;
    mapping(address => bool) private rebateWithdrawn;
    mapping(address => bool) private rebateBurned;
    address public immutable TICKET_ADDRESS;
    uint public immutable TICKET_RESERVE_PRICE;
    uint public immutable TICKET_SUPPLY;
    bool public auctionEnded = false;
    bool public auctionOccured = false;
    bool public rebatePeriod = false;
    uint private capitalSpentInAuction = 0;
    bool public attended = false;
    struct Bid{
        address beneficiary;
        uint256 desiredAmount;
        uint256 amountStaked;
        string spotifyHandle;
    }

    //list of bids we get
    Bid[] private bids;
    mapping(address beneficiary => string handle) private handles;
    mapping(string handle => uint256 bidAmount) private bidAmounts; 
    mapping(address beneficiary => uint256 refund) private bidRefunds;
    mapping(string handle => bool matched) private handlesMatched;

    //assumes equal amount of ticket types
    constructor (address _ticketsAddress, uint _ticketSupply, uint _ticketReservePrice) {
        require(_ticketSupply > 0, 'Must provide supply');
        require(_ticketReservePrice > 0, 'Must provide reserve price');
        
        TICKET_SUPPLY = _ticketSupply;
        TICKET_RESERVE_PRICE = _ticketReservePrice;
        TICKET_ADDRESS = _ticketsAddress;
    }

    function startAuction() public onlyOwner {
        auctionOccured = true;
    }
    function endAuction() public onlyOwner {
        require(auctionOccured, "auction never started");
        auctionEnded = true;
        rebatePeriod = true;
    }

    function bid(uint ticketType) external payable {
        require(ticketType == 0 || ticketType == 1 || ticketType == 2 || ticketType == 3, "Token does not exist");
        require(Suave.isConfidential());
        bytes memory confidentialInputs = Suave.confidentialInputs();

        require (bribeData.lenght > 30, "Spotify bid not long enough"); //spotify handles are max 30 chars
        bytes memory bribeeUsernameBytes = new bytes(30);
        bytes memory spotifyBytes = new bytes(bribeData.length - 30);

        for (uint i = 0; i < 30; i++) {
            bribeUsernameBytes[i] = bribeData[i];
        }

        for (uint j = 30; j < bribeData.length; j++) {
            spotifyBytes[j - 15] = bribeData[j];
        }

        string memory bribeeUsername = string(bribeeUsernameBtres);
        string memory spotify = string(spotifyBytes);

        Bid memory newBid = Bid({
            bribeeUsername: bribeeUsername,
            spotify: spotify,
            bribeeAddr: 0x0,
            bribeAmount: msg.value
        });

        bids.push(newBid);
    }

    function matchBids(string handle, uint256 multiplier) public onlyOnwer {
        // owner can match bids of their top fans
        bidAmounts[handle] = bitAmounts[handle] * multiplier;
        handlesMatched[handle] = true;
    }
}
