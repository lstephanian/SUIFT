const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@openzeppelin/test-helpers');
require("@nomicfoundation/hardhat-toolbox");

describe("Auction", function () {
  let owner;
  let currentTime;
  let auction;
  let Auction;
  let auctionContract;
  let Tickets;
  let tickets;
  let ticketsContract;
  const day = 60 * 60 * 24;
  let fiveDays = 5 * day;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
    // get timestamp
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    currentTime = blockBefore.timestamp;

    //deploy tickets contract
    Tickets = await ethers.getContractFactory("Tickets");
    tickets = await Tickets.deploy();
    ticketsContract = await tickets.deployed();

    //deploy auction contract
    Auction = (await ethers.getContractFactory("Auction"));
    auction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 1, 1);
    auctionContract = await auction.deployed();
  });
  
  it("should deploy successfully", async function () {
    expect(await auctionContract.address).to.be.properAddress;
  });
  it("shouldn't accept incorect ticket id", async function () {
    await expect(Auction.deploy(ticketsContract.address, 4, currentTime, fiveDays, fiveDays, 1, 1)).to.be.reverted;
  });
  it("should require auction start time greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 0, 1, 1, 1, 1)).to.be.reverted;
  });
  it("should require bidding length greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, currentTime, 0, 1, 1, 1)).to.be.reverted;
  });
  it("should require rebate length greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, 0, 1, 1)).to.be.reverted;
  });
  it("should require ticket supply greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 0, 1)).to.be.reverted;
  });
  it("should require reserve price greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 1, 0)).to.be.reverted;
  });
  describe("bid", function () {

    it("can't submit before auction is open", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime + fiveDays, fiveDays, fiveDays, 50, 1);
      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction is not yet active");      
    });
    it("can't submit bid after auction closed", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime - fiveDays, fiveDays, fiveDays, 50, 1);
      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction has ended");      
    });
    it("can't submit bid after auction has been manually ended", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 50, 1);
      await myAuction.auctionEnd();

      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction has ended");      
    });
    it("can't submit bid after auction has been manually ended", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 50, 10);
      await myAuction.auctionEnd();

      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction has ended");      
    });
  });
});
