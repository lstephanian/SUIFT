# SUIFT

Authored by <a href="https://twitter.com/stephensonmatt">Matt Stephenson</a>, <a href="https://twitter.com/sxysun1">Xynyuan Sun</a>, and <a href="https://twitter.com/lstephanian">Lauren Stephanian</a>

Every few years artists go on tour and try to sell fans tickets at the price they deem fair. And each time they do this, many of those under-priced tickets are intercepted by bots and brokers, costing the artist and her fans vast amounts of money almost certainly in the billions of dollars.

But there’s now an answer: <b>SUIFT</b>, the <b>S</b>afe <b>U</b>ser <b>I</b>nception For <b>T</b>ickets. SUIFT uses a unique auction mechanism to ensure:
a. The ticket sales process is trustworthy
b. The only purchasers of an artist’s tickets should be the true fans, not resellers.
c. Ticket buyers pay only the artist’s chosen face value of the tickets.

Sound too good to be true? Let’s dive in.

<b>The Ticketing Industry</b>
<p>Famous artists are in a repeated game with their fans. When they go on tour, they seek to choose “cooperate” by charging their fans a little less than they might be willing to pay. But this is surprisingly difficult to implement in practice, with some experts claiming the only solution is to effectively charge the “defect” price or to try and prevent ticket resale which has proven extremely difficult.

The problem is that, as much as an artist might like to “cooperate”, forcing them to “defect” on their fans can be worth billions. Comparably enormous resale profits go to professional brokers who are not publicly known. But they have gamed the system so thoroughly that, according to a government report, they now “represent either the majority or overwhelming majority of ticket sales”. Artists want to sell to fans, at a cooperative price, but professional brokers intercept.

<b>How SUIFT Fixes This</b>
<p>Right now tickets are typically sold by just opening the floodgates on an ostensibly first come, first serve basis. The result, as described above, is that specialized professional resellers win the majority, if not the “overwhelming majority” of the tickets intended for fans. SUIFT can improve on this by running an effective auction using Flashbots’ SUAVE. SUAVE allows all parties to verify that the auction is being run fairly, while also protecting the valuable information that can otherwise allow auctions to be manipulated.

While running a credible auction is an improvement, we have not yet addressed the artist’s wishes that fans only pay the cooperative face value for the tickets. To accomplish this, we can do two things:

Refund the difference between the auction price and the “Face value price” to everyone who attends the show. This means, when a fan enters the venue the night of the show, they get refunded the difference between what they paid in auction and the intended face value. Assume the ticket’s face value is $100, but it went at auction for $300. The night of the concert, when a fan shows their ticket at the venue, they are admitted to the show AND refunded $200.

Allow artists to “amplify” the bids of those they have identified as true fans. We explain this further in the appendix, but the essential upshot is that an artist can use our SUIFT contract to select some set of fans who get their bids automatically increased at no cost to them. That is, if the artist chooses double the bid of every fan, and a fan bids $100, it will be as if they had bid $200. If the winning price is $200, the fan wins the ticket but pays only $100.

The “refund at the show” approach uniquely benefits fans based on their willingness to actually attend the show. And the “amplify the bids” approach rewards fans who might be budget constrained or, offer some additional value to the show beyond what they are willing to pay. These two together segment the market such that only true fans should ever want to hold a ticket.

The price is right, but only for true fans.
<p>
<p>
<b>Read More Here: https://suift.tickets</b>