const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
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
    it("can't submit bid lower than the minimum bid index", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(owner).bid({value:5});
      await myAuction.connect(addr1).bid({value:6});
      await myAuction.connect(addr1).bid({value:7});

      await expect(
        myAuction.connect(addr3).bid({value:4})
        ).to.be.revertedWith('Your bid is lower than the minimum');      
    });
    it("should emit an event upon bid", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      expect(await myAuction.connect(owner).bid({value:2}))
        .to.emit(myAuction, "BidEntered");
    });
    it("should be able to change minBidAmount", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await expect(myAuction.connect(owner).bid({value:5})).to.emit(myAuction, "BidEntered").withArgs(anyValue, 5);
      await expect(myAuction.connect(addr1).bid({value:6})).to.emit(myAuction, "BidEntered").withArgs(anyValue, 6);
      await expect(myAuction.connect(addr2).bid({value:7})).to.emit(myAuction, "MinBidUpdated").withArgs(7);
    });
  });
  describe("withdrawOverbid", function () {
    it("should allow an overbid participant to withdraw their bid", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await expect(myAuction.connect(addr1).bid({value:5})); //overbid
      await expect(myAuction.connect(addr2).bid({value:6}));
      await expect(myAuction.connect(addr3).bid({value:7}));

      let balAfterBid = await provider.getBalance(addr1.address);
      await myAuction.connect(addr1).withdrawOverbid();
      let balAfterWithdraw = await provider.getBalance(addr1.address);
      let diff = balAfterWithdraw - balAfterBid; 

      expect(balAfterWithdraw > balAfterBid);
    });
    it("should not allow someone who hasn't bid to withdraw", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await expect(myAuction.connect(addr3).withdrawOverbid()).to.be.reverted;
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
  describe("mintTicketsToWinners", function () {
    it("only owner can mint tickets", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await expect(myAuction.connect(addr3).mintTicketsToWinners()).to.be.reverted;
    });
    it("tickets go to auction winners", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(addr2).bid({value:20});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners();

      //check balance of addr1
      let ticketBalance = await ticketsContract.balanceOf(addr1.address, 0);
      expect (ticketBalance).to.equal(1);
    });
  });
  describe("setAttendConcert", function () {
    it("emits event when address is marked as attended", async function () {
      await expect(auctionContract.connect(owner).setAttendConcert(addr1.address)).to.emit(auctionContract, "AttendedEvent").withArgs(addr1.address);
    });
  });
  describe("rebateWithdraw", function () {
    it("allows attendees to withdraw", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners(); 
      await myAuction.connect(owner).setAttendConcert(addr1.address);
      let success = await myAuction.connect(addr1).rebateWithdraw();
      
      expect (success).to.equal(true);
    });
    it("stops non-attendees from withdrawing", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners(); 
      await expect(myAuction.connect(addr1).rebateWithdraw()).to.revertedWith("You did not attend the event");
    });
    it("does not allow withdrawals outside the rebate period", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners(); 
      await myAuction.connect(owner).setAttendConcert(addr1.address);
      await time.increase(fiveDays + fiveDays + day);

      await expect(myAuction.connect(addr1).rebateWithdraw()).to.revertedWith("It's not rebate period");

    });
  });
  describe("burnRebate", function () {
    it("only owner can burn cash", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners(); 
      await myAuction.connect(owner).setAttendConcert(addr1.address);
      await time.increase(fiveDays * 3);

      await expect(myAuction.connect(addr1).burnRebate(addr2.address)).to.be.reverted;
    });
    it("owner can only burn cash if it hasn't been withdrawn", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners(); 
      await myAuction.connect(owner).setAttendConcert(addr1.address);
      await myAuction.connect(addr1).rebateWithdraw();
      await time.increase(fiveDays * 3);

      await expect(myAuction.connect(owner).burnRebate(addr2.address)).to.be.revertedWith("Participant already withdrew their rebate");
    });
    it("owner can only burn cash if earmarked amount hasn't been burned already", async function () {
      let myAuction = await Auction.deploy(ticketsContract.address, 0, currentTime, fiveDays, fiveDays, 2, 1);
      await myAuction.connect(addr1).bid({value:10});
      await myAuction.connect(owner).auctionEnd();
      await ticketsContract.transferOwnership(myAuction.address);
      await myAuction.connect(owner).mintTicketsToWinners(); 
      await myAuction.connect(owner).setAttendConcert(addr1.address);
      await time.increase(fiveDays * 3);
      await myAuction.connect(owner).burnRebate(addr2.address);

      await expect(myAuction.connect(owner).burnRebate(addr2.address)).to.be.revertedWith("Participant already had their rebate burned");
    });
  });
  
});
