// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './Auction.sol';

contract AuctionFactory {
    address[] public auctions;
    address public immutable ticketsAddress; //need to set this
    event AuctionCreated(Auction auctionContract, address owner, uint numAuctions);

    //create our 4 auctions
    function createAuctions() public {
        //floor seats
        Auction floorSeatAuction = new Auction(ticketsAddress, floorSeatId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, floorSeatTicketSupply, floorSeatTicketPrice);
        auctions.push(address(floorSeatAuction));
        emit AuctionCreated(address(floorSeatAuction), msg.sender);

        //front row seats
        Auction frontRowAuction = new Auction(ticketsAddress, frontRowId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, frontRowTicketSupply, frontRowTicketPrice);
        auctions.push(address(frontRowAuction));
        emit AuctionCreated(address(frontRowAuction), msg.sender);

        //middle row seats
        Auction middleRowAuction = new Auction(ticketsAddress, middleRowId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, middleRowTicketSupply, middleRowTicketPrice);
        auctions.push(address(middleRowAuction));
        emit AuctionCreated(address(middleRowAuction), msg.sender);

        //nosebleed seats
        Auction noseBleedAuction = new Auction(ticketsAddress, noseBleedId, AUCTION_START_TIME, AUCTION_LENGTH, REBATE_LENGTH, noseBleedTicketSupply, noseBleedTicketPrice);
        auctions.push(address(noseBleedAuction));
        emit AuctionCreated(address(noseBleedAuction), msg.sender);
    }

    function allAuctions() public view returns (address[]) {
        return auctions;
    }
}