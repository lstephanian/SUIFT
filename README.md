# SUIFT
two ticketmaster employees engaging in a top secret project


walkthrough:
1. Ticket seller sets minimum ticket price 
2. Require that the block time is less than auction end time
3. Allow bids
    1. Require bid is equal to or higher than minimum ticket price
    2. If the number of bids entered is less than the number of tickets being sold then update the queue with beneficiary address, price bid, and time of bid
    3. Otherwise if there are more than TICKET_SUPPLY amount of bids AND if the bid is higher than the lowest bid in the bid list array then:
        1. Remove the lowest bid from the queue (or most recent lowest bid if there are multiple bids at the same price)
    4. Set withdraw function so people can withdraw their bid if they do not win tickets
    5. Once the real life event has taken place we are given  (off chain) information about which addresses have attended the event. 
    6. The delta between the initial set reserve price of the ticket and the price paid by beneficiary is aggregated and distributed pro-rata to beneficiaries who actually attend. 
