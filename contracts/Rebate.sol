// SPDX-License-Identifier: GPL-3.0
// We aggregate all capital spent in auction above ticket reserve price
// If a ticketholder actually attends the event, we distribute pro-rata amount of aggregated capital back to them

pragma solidity >=0.7.0 <0.9.0;

import "./Auction.sol"; //import auction contract for calculating capital spent

uint capitalSpentInAuction;
bool ended;  // Set to true at the end, disallows any change.
bool attended = false;
uint REBATE_END_TIME; //need to have an end time because for beneficiaries who buy tickets and do not attend, the rebate will simply be burned


contract Rebate {
    
    function attendedConcert(address participant) public returns(bool) {
        // check if address attended concert

        // return(beneficiaryMapping[participant])
    }

    function _calcProRata(address participant) private returns(uint){
        //for x in [bidarray]:
            //capitalSpentInAuction += x
        // uint delta = capitalSpentInAuction - Auction.TICKET_SUPPLY * Auction.TICKET_RESERVE_PRICE

        // uint proRata = beneficiaryMapping[participant] - Auction.TICKET_RESERVE_PRICE
    }
    function distributeRebate(address participant) public {
        require(Auction.ended, "The auction is not over");
        require(ended = false, "The rebate period is over");
        require(attended = true, "You did not attend the event"); //determine whether they attended off-chain

        //if participant was at the event then allow them to withdraw their pro-rata
    }

    function burnRebate() public{
        require(Auction.ended, "The auction is not over");
        require(ended, "The rebate period is not over");
        require(attended = false, "Participant did attend the event");
        
        //if participant was not at event then burn their rebate
    }
}