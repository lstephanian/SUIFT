// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// based in part on https://docs.soliditylang.org/en/v0.8.3/solidity-by-example.html#blind-auction
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "./Queue.sol"; //Using Erick Dagenais' priority queue implementation

contract Auction is ERC1155Holder {
    using Queue for QueueStorage.QueueStorage; // using queue lib
    QueueStorage.QueueStorage public bidQueue;

    address payable public beneficiary; //address submitting bid
    uint public AUCTION_START_TIME;
    uint public AUCTION_END_TIME; 
    uint public TICKET_SUPPLY;
    uint public TICKET_RESERVE_PRICE;

    mapping(address => uint) balances;
    uint[] private bids; //array of bids - might need to delete this
    uint public current_min_price; //current lowest acceptable bid
    bool ended;  // Set to true at the end, disallows any change.
    uint public numBids = 0; //current number of bids


    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /// Create an english batched auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        uint _biddingTime,
    ) {
        beneficiary = _beneficiary;
        bidQueue.initialize();
    }

    //Eventually need to enable bidding on different seat types (hence 1155)
    function bid(uint256 price) external payable {
        require(block.timestamp >= AUCTION_START_TIME, "The auction is not yet active");
        require(block.timestamp <= AUCTION_END_TIME, "The auction has ended");
        require(msg.value >= TICKET_RESERVE_PRICE, "The bid cannot be lower than ticket value")

        //check whether number of bids is less than total ticket supply
        if (TICKET_SUPPLY > numBids) {
            //TODO: enqueue - add beneficiary, price info, and bidtime info to queue
            numBids += 1; //people can bid on one ticket at a time
            
            //emit event indicating a bid has been placed
            emit BidEntered(msg.sender, msg.value);
        }
        else {
            require(msg.value > current_min_price, "Your bid is lower than the current minimum");

            //if the bid is higher than the current minimum price then add it to the queue and kick lowest most recent bid out
            //TODO: everyone will need to have the ability to withdraw if their bid is not selected

            //current_min_price = TODO: get current min price from Queue
            //remove most recent lowest bidder from Queue.

            emit MinBidIncreased(msg.sender, msg.value);

        }


    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = balances[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {

        // 1. Conditions
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        //3. Transfer tickets
        //TODO: transfer 1155 token (the ticket) to bidders
    }
}
//TODO: create contract for pulling attendance info off chain and using that to distribute pro-rata amounts to participants