# SUIFT

walkthrough:
1. Ticket seller sets minimum ticket price 
2. While auction is open, allow bids
    1. Require bid is equal to or higher than minimum ticket price
    2. If the number of bids entered is less than the number of tickets being sold then update the queue with beneficiary address, price bid, and time of bid
    3. Otherwise if there are more than TICKET_SUPPLY amount of bids AND if the bid is higher than the lowest bid in the bid list array then:
        1. Remove the lowest bid from the queue (or most recent lowest bid if there are multiple bids at the same price)
3. After auction is closed, rebate period begins
        1. For non winnesr: set withdraw function so people can withdraw their bid if they do not win tickets
        2. After event occurs in real life (off chain) we are given information about which addresses have attended the event
        3. The delta between the initial set reserve price of the ticket and the price paid by beneficiary is aggregated and distributed pro-rata to beneficiaries who actually attend.
4. After the rebate period is over, any leftover ETH is burned. This is to prevent anyone from benefitting by somehow preventing people to attend the event.

