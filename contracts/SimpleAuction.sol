

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

contract SimpleAuction is ERC1155Holder {
// SPDX-License-Identifier: GPL-3.0

    // Parameters of the auction
    uint maxNumBids = 100;
    address payable public beneficiary;
    address[] beneficiaries;
    uint public auctionEndTime;
    uint[] private bidList;

    // Current state of the auction.
    address public highestBidder;
    uint public current_min;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        uint _biddingTime,
        int num_tickets
    ) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid() public payable {

        // Revert the call if the bidding period is over.
        require(
            block.timestamp <= auctionEndTime,
            "Auction already ended."
        );

        //if the current number of bids is less than the set max, then add that bid to bidlist and bidder info to mapping
        if (bidList.length < maxNumBids) {
            bidList[].push(msg.value);
            beneficiaries[beneficiary] += msg.value;
        }

        // If the bid is not in the top [ticket_num], send the money back (failing require reverts txn)
        else {
            //determine if msg.value is higher than any of the other bids
            uint lowest = 0;
            uint b;

            //find lowest bid
            for (b = 0; b < bidList.length; b++){
                if (bidList[b] < lowest) {
                    lowest = bidList[b];
                }
            }

            // msg.value has to be higher than the lowest bid otherwise revert
            require(
                msg.value > lowest,
                "There already is a higher bid."
            );

            // update bidList and beneficiary mapping info
            delete bidList[b]; // is b still lowest
            bidList.push(msg.value);
            beneficiaries[beneficiary] += msg.value;
            //search beneficiaries for that bid and remove beneficiary 

        }


        

        //pull current_min bid value
        require(
            
            msg.value > current_min,
            "There already is a higher bid."
        );

        if (current_min != 0 && msg.value > current_min) {
            beneficiaries[beneficiary] += bid;
            pendingReturns[highestBidder] += highestBid;
        }
        winner = msg.sender;
        winning_bid = msg.value;
        emit MinBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
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

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}