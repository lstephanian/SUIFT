const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@openzeppelin/test-helpers');
require("@nomicfoundation/hardhat-toolbox");

describe("Tickets", function () {
  describe("Auction", function () {
    let owner;
    let addr1;
    let Tickets;
    let tickets;
    let ticketsContract;
  
    beforeEach(async function () {
      [owner, addr1] = await ethers.getSigners();
  
      Tickets = await ethers.getContractFactory("Tickets");
      tickets = await Tickets.deploy();
      ticketsContract = await tickets.deployed();
    });
  
    it("should deploy successfully", async function () {
      expect(await ticketsContract.address).to.be.properAddress;
    });
    it("should be able to mint tickets", async function () {
      await ticketsContract.connect(owner).mint(addr1.address, 0, 1);
      let ticketBalance = await ticketsContract.balanceOf(addr1.address, 0);
      expect (ticketBalance).to.equal(1);
    });
    it("only owner should be able to mint", async function () {
      await expect(ticketsContract.connect(addr1).mint(addr1.address, 0, 1)).to.be.reverted;
    });
    it("can only mint allowed ticket ids", async function () {
      await expect(ticketsContract.connect(owner).mint(addr1.address, 4, 1)).to.be.reverted;
    });
  });
});
