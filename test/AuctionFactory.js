const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@openzeppelin/test-helpers');
require("@nomicfoundation/hardhat-toolbox");

describe("AuctionFactory", function () {
  let owner;

  beforeEach(async function () {
    owner = await ethers.getSigners();
    const currTime = await ethers.provider.getBlock(ethers.provider.getBlockNumber()).timestamp;

    //deploy tickets contract and get address to use for deploying auction
    const Tickets = await ethers.getContractFactory("Tickets");
    const tickets = await Tickets.deploy();
    const ticketsContract = await tickets.deployed();

    //deploy auction factory contract
    const AuctionFactory = await ethers.getContractFactory("Auction");
    const auctionFactory = await AuctionFactory.deploy();
    const auctionFactoryContract = await auctionFactory.deployed();
  });
  
  it('should deploy and set the owner correctly', async function () {
    expect(await auctionFactoryContract.owner()).to.equal(owner.address);
  });
  it('should deploy an auction', async function () {
    auction = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift floor seat auction", 0, currTime, 120, 120, 100, 100);
    expect(auction.owner()).to.equal(owner.address);
  });
  it('should create an array of deployed auctions', async function () {
    floorSeatsAuction = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift floor seat auction", 0, currTime, 120, 120, 100, 400);
    frontRowSeatsAuction = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift front row seat auction", 1, currTime, 120, 120, 100, 300);
    middleRowSeatsAuction = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift middle row seat auction", 1, currTime, 120, 120, 100, 200);
    nosebleedSeatsAuction = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift back row seat auction", 1, currTime, 120, 120, 100, 100);

    //expect array to output 4 diff auctions
    expect(length(auctionFactoryContract.allAuctions)).to.equal.apply(4);
  });
});
