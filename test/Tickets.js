const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@openzeppelin/test-helpers');
require("@nomicfoundation/hardhat-toolbox");

describe("Tickets", function () {
  let owner;
  let addr1;
  let addr2;
  let addr3;

  beforeEach(async function () {
    // const oneEth = ethers.BigNumber.from("1000000000000000000");
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const currTime = await ethers.provider.getBlock(ethers.provider.getBlockNumber()).timestamp;
    const auctionTicketsId = 0;
    const startTime = 1; //.5 mins from last block
    const biddingLength = 1; //2 mins
    const rebateLength = 1; //2 mins
    const ticketSupply = 1;
    const ticketReservePrice = 1;
    
    const Auction = await ethers.getContractFactory("Auction");
    const auction = await Auction.deploy(auctionTicketsId, startTime, biddingLength, rebateLength, ticketSupply, ticketReservePrice);
    const contract = await auction.deployed();
  });
  
  it("should deploy successfully", async function () {
    console.log("contract address", Auction.address);
  });
  // it("can't submit bid before auction is open", async function () {
  //   await expect(
  //     contract.connect(addr1).bid({from: owner, value: ethers.utils.parseUnits(oneEth.mul(4))})
  //   ).to.be.revertedWith("The auction is not yet active");
  // });

});
