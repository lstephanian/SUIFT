const { expect } = require("chai");
const { ethers, waffle} = require("hardhat");
const { time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");


describe("AuctionFactory", function () {
  let owner;
  let currTime;
  let auctionFactory;
  let AuctionFactory;
  let auctionFactoryContract;
  let Tickets;
  let tickets;
  let ticketsContract;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    currTime = await ethers.provider.getBlock(ethers.provider.getBlockNumber()).timestamp;

    //deploy tickets contract and get address to use for deploying auction
    Tickets = await ethers.getContractFactory("Tickets");
    tickets = await Tickets.deploy();
    ticketsContract = await tickets.deployed();

    //deploy auction factory contract
    AuctionFactory = await ethers.getContractFactory("AuctionFactory");
    auctionFactory = await AuctionFactory.deploy();
    auctionFactoryContract = await auctionFactory.deployed();
  });
  
  it('should deploy correctly', async function () {
    expect(await auctionFactoryContract.address).to.be.properAddress;
  });
  it('should deploy an auction', async function () {
    auction = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift floor seat auction", 0, 1, 1, 1, 1, 1);
    auctionAddress = await auctionFactoryContract.allAuctions();
    expect(auctionAddress).to.be.properAddress;
  });
  it('should store deployed auctions in an array', async function () {
    let a = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift floor seat auction", 0, 1, 1, 1, 1, 1);
    let b = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift front row seat auction", 1, 1, 1, 1, 1, 1);
    let c = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift middle row seat auction", 2, 1, 1, 1, 1, 1);
    let d = await auctionFactoryContract.createAuction(ticketsContract.address, "t swift back row seat auction", 3, 1, 1, 1, 1, 1);

    //expect array to output 4 diff auctions
    expect((await auctionFactoryContract.allAuctions()).length).to.equal(4);
  });
});
