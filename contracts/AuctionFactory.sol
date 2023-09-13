// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './Auction.sol';

contract AuctionFactory {
    Auction[] public auctions;
    uint public immutable AUCTION_START_TIME = block.timestamp;
    uint public immutable AUCTION_LENGTH = 432000; //30 days
    uint public immutable REBATE_LENGTH = 432000; //60 days
    uint public immutable noseBleedTicketSupply = 250;
    uint public immutable middleRowTicketSupply = 250;
    uint public immutable frontRowTicketSupply = 250;
    uint public immutable floorSeatTicketSupply = 250;
    uint public immutable noseBleedTicketPrice = 1;
    uint public immutable middleRowTicketPrice = 2;
    uint public immutable frontRowTicketPrice = 3;
    uint public immutable floorSeatTicketPrice = 4;
    uint public immutable noseBleedId = 3; 
    uint public immutable middleRowId = 2;
    uint public immutable frontRowId = 1;
    uint public immutable floorSeatId = 0;

    event AuctionCreated(Auction auctionContract, address owner, uint numAuctions);

    //create our 4 auctions
    function createAuctions() public {
        //floor seats
        Auction floorSeatAuction = new Auction(floorSeatId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, floorSeatTicketSupply, floorSeatTicketPrice);
        auctions.push(floorSeatAuction);
        emit AuctionCreated(floorSeatAuction, msg.sender, auctions.length);

        //front row seats
        Auction frontRowAuction = new Auction(frontRowId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, frontRowTicketSupply, frontRowTicketPrice);
        auctions.push(frontRowAuction);
        emit AuctionCreated(frontRowAuction, msg.sender, auctions.length);

        //middle row seats
        Auction middleRowAuction = new Auction(middleRowId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, middleRowTicketSupply, middleRowTicketPrice);
        auctions.push(middleRowAuction);
        emit AuctionCreated(middleRowAuction, msg.sender, auctions.length);

        //nosebleed seats
        Auction noseBleedAuction = new Auction(noseBleedId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, noseBleedTicketSupply, noseBleedTicketPrice);
        auctions.push(noseBleedAuction);
        emit AuctionCreated(noseBleedAuction, msg.sender, auctions.length);
    }

    function allAuctions() public view returns (Auction[] memory) {
        return auctions;
    }
}