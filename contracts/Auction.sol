// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// based in part on https://docs.soliditylang.org/en/v0.8.3/solidity-by-example.html#blind-auction
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Auction is ERC1155Holder {
    uint public immutable AUCTION_START_TIME;
    uint public immutable AUCTION_END_TIME;
    bool public ended;
    struct Bid{
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
    }

    Bid[] private bids;
    mapping(address beneficiary => uint256 refund) private bidRefunds;

    event BidEntered(address indexed beneficiary, uint256 indexed amount);
    event BitRefundReceived(address indexed beneficiary, uint256 indexed amount);


    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    constructor(uint256 _startTime, uint _biddingTime, uint _ticketSupply, uint _ticketReservePrice) 
    {
        require(_startTime > 0, 'Must provide start time');
        require(_endTime > 0, 'Must provide end time');
        require(_ticketSupply > 0, 'Must provide supply');
        require(_ticketReservePrice > 0, 'Must provide reserve price');

        AUCTION_START_TIME = _startTime;
        AUCTION_END_TIME = _startTime + _biddingTime;
        TICKET_SUPPLY = _ticketSupply;
        TICKET_RESERVE_PRICE = _ticketReservePrice;
        ended = false;
    }

    function bid() external payable {
        require(block.timestamp >= AUCTION_START_TIME, "The auction is not yet active");
        require(block.timestamp <= AUCTION_END_TIME, "The auction has ended");
        require(ended == false, "The auction has ended");
        require(msg.value >= TICKET_RESERVE_PRICE, "The bid cannot be lower than ticket value");

        uint minBidIndex = _minBidIndex();

        require(msg.value > bids[minBidIndex], 'Your bid lower than the minimum');
        
        //create a bid struct: beneficiary, bid amount, time of bid
        Bid memory bid = Bid(msg.sender, msg.value, block.timestamp); 

        //check whether number of bids is less than total ticket supply
        if (TICKET_SUPPLY > bids.length) {
            
            //add bid to bid struct
            bids.push(Bid);

            //emit event indicating a bid has been placed
            emit BidEntered(msg.sender, msg.value);

            return;
        }
        _replaceLowestBid(bid, minBidIndex);

        emit MinBidIncreased(msg.sender, msg.value);
    }

    //Enable withdrawals for bids that have been overbid
    function withdraw() external returns (bool) {
        uint256 amount = bidRefunds[msg.sender];
        require(amount != 0, 'Nothing to withdraw');

        bidRefunds[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{ value: amount }('');
        require(success);

        return(success);
        emit BitRefundReceived(msg.sender, amount);
    }


    /// End the auction and send the highest bid to the beneficiary.
    function auctionEnd() public {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        emit AuctionEnded();

        //3. Transfer tickets
        //TODO: transfer 1155 token (the ticket) to bidders
    }

    //replaces one of the lowest accepted bids in the auction with this latest bid and adds a refund to the beneficiary who was overbid
    //Note: this could be improved by looping through timestamps and determining who was the most recent lowest bid
    function _replaceLowestBid(Bid bid, uint256 minBidIndex) internal {
        Bid storage currentBid = bids[minBidIndex];
        bidRefunds[currentBid.beneficiary] += currentBid.amount;
        currentBid = bid;
    }

    //loops through index of bids and if the bid amount is greater than the minimum bid amount, then add it to the bidindex
    function _minBidIndex() internal view returns (uint256 minIndex) {
        uint minAmount;
        for(uint256 i; i < bids.length; i++) {
        Bid storage bid = bids[i];

        if (bid.amount < minAmount || minAmount == 0) {
                minIndex = i;
                minAmount = bid.amount;
        }
    }
}

