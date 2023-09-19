const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@openzeppelin/test-helpers');
require("@nomicfoundation/hardhat-toolbox");

describe("Auction", function () {
  let owner;
  let currTime;
  let auction;
  let Auction;
  let auctionContract;
  let Tickets;
  let tickets;
  let ticketsContract;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    currTime = await ethers.provider.getBlock(ethers.provider.getBlockNumber()).timestamp;

    //deploy tickets contract
    Tickets = await ethers.getContractFactory("Tickets");
    tickets = await Tickets.deploy();
    ticketsContract = await tickets.deployed();

    //deploy auction contract
    Auction = (await ethers.getContractFactory("Auction"));
    auction = await Auction.deploy(ticketsContract.address, 0, 1, 1, 1, 1, 1);
    auctionContract = await auction.deployed();
  });
  
  it("should deploy successfully", async function () {
    expect(await auctionContract.address).to.be.properAddress;
  });
  it("shouldn't accept incorect ticket id", async function () {
    await expect(Auction.deploy(ticketsContract.address, 4, 1, 1, 1, 1, 1)).to.be.reverted;
  });
  it("should require auction start time greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 0, 1, 1, 1, 1)).to.be.reverted;
  });
  it("should require bidding length greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 1, 0, 1, 1, 1)).to.be.reverted;
  });
  it("should require rebate length greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 1, 1, 0, 1, 1)).to.be.reverted;
  });
  it("should require ticket supply greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 1, 1, 1, 0, 1)).to.be.reverted;
  });
  it("should require reserve price greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 1, 1, 1, 1, 0)).to.be.reverted;
  });
  describe("bid", function () {
    // it("can't submit before auction is open", async function () {
    //   let myAuction = await Auction.deploy(ticketsContract.address, 0, 1, 1, 1, 1, 1);
    //   await expect(
    //     myAuction.connect(addr1).bid({from: owner, value: ethers.utils.parseUnits(oneEth.mul(4))})
    //   ).to.be.revertedWith("The auction is not yet active");
    // });
  });
});
