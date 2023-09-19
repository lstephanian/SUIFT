// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

import './Auction.sol';

contract AuctionFactory {
    address[] public auctions;
    event AuctionCreated(address auctionContract, address owner, string name);

    //create our 4 auctions
    function createAuction(address ticketsAddress, string memory auctionName, uint floorSeatId, uint auctionStartTime, uint auctionLength, uint rebateLength, uint ticketSupply, uint ticketPrice) public {
        Auction auction = new Auction(ticketsAddress, floorSeatId, auctionStartTime, auctionLength, rebateLength, ticketSupply, ticketPrice);
        auctions.push(address(auction));
        emit AuctionCreated(address(auction), msg.sender, auctionName);
    }

    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
}