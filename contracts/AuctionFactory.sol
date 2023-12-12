// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

import './Auction.sol';

contract AuctionFactory {
    address[] public auctions;
    event AuctionCreated(address auctionContract, address owner);

    //create our 4 auctions
    function createAuction(address ticketsAddress, uint auctionTicketsId, uint ticketSupply, uint ticketReservePrice, address charity) public {
        Auction auction = new Auction(ticketsAddress, auctionTicketsId, ticketSupply, ticketReservePrice, charity);
        auctions.push(address(auction));
        emit AuctionCreated(address(auction), msg.sender);
    }

    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
}