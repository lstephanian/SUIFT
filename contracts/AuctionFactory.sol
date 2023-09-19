// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import './Auction.sol';

contract AuctionFactory {
    address[] public auctions;
    address public immutable ticketsAddress; //need to set this
    event AuctionCreated(Auction auctionContract, address owner, uint numAuctions, string name);

    //create our 4 auctions
    function createAuctions(address ticketsAddress, string auctionName, uint floorSeatId, uint auctionStartTime, uint auctionLength, uint rebateLength, uint ticketSupply, uint ticketPrice) public {
        Auction auction = new Auction(ticketsAddress, floorSeatId, auctionStartTime, auctionLength, rebateLength, ticketSupply, ticketPrice);
        auctions.push(address(auction));
        emit AuctionCreated(address(floorSeatAuction), msg.sender, auctionName);
    }

    function allAuctions() public view returns (address[]) {
        return auctions;
    }
}