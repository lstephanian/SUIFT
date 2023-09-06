// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import { Auction } from './Auction.sol';

contract AuctionFactory {
    address[] public auctions;
    uint public immutable AUCTION_START_TIME = block.timestamp;
    uint public immutable AUCTION_LENGTH = 432000; //30 days
    uint public immutable REBATE_LENGTH = 432000; //60 days
    uint public immutable noseBleedTicketSupply = 250;
    uint public immutable middleRowTicketSupply = 250;
    uint public immutable frontRowTicketSupply = 250;
    uint public immutable floorSeatTicketSupply = 250;
    uint public immutable noseBleedTicketPrice = 0.5;
    uint public immutable middleRowTicketPrice = 0.75;
    uint public immutable frontRowTicketPrice = 1;
    uint public immutable floorSeatTicketPrice = 2;



    event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

    //create our 4 auctions
    function createNosebleedAuction(uint256 startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) {
        Auction newAuction = new Auction(AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, noseBleedTicketSuppl, noseBleedTicketPrice);
        auctions.push(newAuction);

        AuctionCreated(newAuction, msg.sender, auctions.length, auctions);
    }
    function createMiddleRowAuction(uint256 startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) {
        Auction newAuction = new Auction(AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, middleRowTicketSupply, middleRowTicketPrice);
        auctions.push(newAuction);

        AuctionCreated(newAuction, msg.sender, auctions.length, auctions);
    }
    function createFrontRowAuction(uint256 startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) {
        Auction newAuction = new Auction(AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, frontRowTicketSupply, frontRowTicketPrice);
        auctions.push(newAuction);

        AuctionCreated(newAuction, msg.sender, auctions.length, auctions);
    }
    function createFloorSeatAuction(uint256 startTime, uint biddingLength, uint rebateLength, uint ticketSupply, uint ticketReservePrice) {
        Auction newAuction = new Auction(AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, floorSeatTicketSupply, floorSeatTicketPrice);
        auctions.push(newAuction);

        AuctionCreated(newAuction, msg.sender, auctions.length, auctions);
    }

    function allAuctions() returns (address[]) {
        return auctions;
    }
}