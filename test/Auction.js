const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
require("@nomicfoundation/hardhat-toolbox");


// TODO: Finish Tests!

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
  const provider = ethers.provider;


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
    auction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
    auctionContract = await auction.deployed();
  });
  
  it("should deploy successfully", async function () {
    expect(await auctionContract.address).to.be.properAddress;
  });
  it("shouldn't accept incorect ticket id", async function () {
    await expect(Auction.deploy(ticketsContract.address, 0, 10, 5, 0x00)).to.be.reverted;
  });
  it("should require ticket supply greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 1, 0, 5, 0x00)).to.be.reverted;
  });
  it("should require reserve price greater than 0", async function () {
    await expect(Auction.deploy(ticketsContract.address, 1, 10, 0, 0x00)).to.be.reverted;
  });
  describe("bid", function () {

    it("can't submit before auction is open", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction is not yet active");      
    });
    it("can't submit bid after auction closed", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction has ended");      
    });
    it("can't submit bid after auction has been manually ended", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      await myAuction.auctionEnd();

      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction has ended");      
    });
    it("can't submit bid after auction has been manually ended", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      await myAuction.auctionEnd();

      await expect(
        myAuction.connect(addr1).bid({value:5})
        ).to.be.revertedWith("The auction has ended");      
    });
    it("can't submit bid lower than the minimum bid index", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      await myAuction.connect(owner).bid({value:5});
      await myAuction.connect(addr1).bid({value:6});
      await myAuction.connect(addr1).bid({value:7});

      await expect(
        myAuction.connect(addr3).bid({value:4})
        ).to.be.revertedWith('Your bid is lower than the minimum');      
    });
    it("should emit an event upon bid", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      expect(await myAuction.connect(owner).bid({value:2}))
        .to.emit(myAuction, "BidEntered");
    });
    it("should be able to change minBidAmount", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 1, 10, 5, 0x00);
      await expect(myAuction.connect(owner).bid({value:5})).to.emit(myAuction, "BidEntered").withArgs(anyValue, 5);
      await expect(myAuction.connect(addr1).bid({value:6})).to.emit(myAuction, "BidEntered").withArgs(anyValue, 6);
      await expect(myAuction.connect(addr2).bid({value:7})).to.emit(myAuction, "MinBidUpdated").withArgs(7);
    });
  });
  describe("auctionEnd", function () {
    it("only owner should be able to end auction", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await expect(myAuction.connect(addr3).auctionEnd()).to.be.reverted;
    });
    it("should end the auction", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await expect(myAuction.connect(owner).auctionEnd()).to.emit(myAuction, "AuctionEnded").withArgs(true);
    });
  });
});
