// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { Auction } from './Auction.sol';

contract AuctionFactory {
    // address[] public auctions;
    Auction[] private auctions;
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
    function createNosebleedAuction(uint _auctionTicketsId, uint startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) public {
        Auction newAuction = new Auction(noseBleedId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, noseBleedTicketSupply, noseBleedTicketPrice);
        auctions.push(newAuction);

        emit AuctionCreated(newAuction, msg.sender, auctions.length);
    }
    function createMiddleRowAuction(uint _auctionTicketsId, uint startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) public {
        Auction newAuction = new Auction(middleRowId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, middleRowTicketSupply, middleRowTicketPrice);
        auctions.push(newAuction);

        emit AuctionCreated(newAuction, msg.sender, auctions.length);
    }
    function createFrontRowAuction(uint _auctionTicketsId, uint startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) public {
        Auction newAuction = new Auction(frontRowId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, frontRowTicketSupply, frontRowTicketPrice);
        auctions.push(newAuction);

        emit AuctionCreated(newAuction, msg.sender, auctions.length);
    }
    function createFloorSeatAuction(uint _auctionTicketsId, uint startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) public {
        Auction newAuction = new Auction(floorSeatId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, floorSeatTicketSupply, floorSeatTicketPrice);
        auctions.push(newAuction);

        emit AuctionCreated(newAuction, msg.sender, auctions.length);
    }

    // function allAuctions() returns (address[]) {
    //     return auctions;
    // }
}