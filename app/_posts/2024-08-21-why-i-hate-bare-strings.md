---
layout: post
category: development
tags:
    - Story
    - Development
title: Why I Hate Bare Strings
---

Back in a previous work life, I kept getting asked the same question every morning. Since I was developing the system
for the business, I wrote some code to answer the question with an automated email every morning. Each day, we would
send out shipment orders to pickup office machines. The question was "when is this particular machine arriving?"

Part of the system would contact the carriers every night to update the status of shipments. Some would be picked up and
en route, some would have problems with the pickup and be on a will-advise status. This information was available on the
dashboard, but showing information about the shipment and leasing company that owned the equipment, not specific
machines. A user could open the page of a particular shipment and see the equipment list, shipment status, and when the
office equipment was resold, the sale price of the equipment. Unfortunately, pressing a few extra buttons was apparently
asking too much for some users, and they wanted to get updates about specific machines.

The code, which was probably some of the best PHP code ever written in the first decade of the 21st Century, would wait
for the updates to complete, then search for the en route machines on the watch list and send an email to the watchers.
I set up a bunch of watch alerts for equipment that had been picked up earlier in the day and went home. The next
morning, no emails. I double checked the code, made some changes, and set up more watches. Again, the next morning, no
email. Again, I look at the code, and think "Hmm, maybe this time it will be different, even though it's exactly the
same," and it was the same. Night after night, I get no email, and chalk it up to "one of those things."

At the time, I had no test suite, and quite honestly, the code at that time was too spaghettified to allow proper
testing without writing to the production database or hard-coding a specific tracking number from a specific carrier
that I already knew to be in a specific status.

But then one day, I discovered how awesome class constants are. You get IDE autocompletion on a constant instead of a
bare string, and the IDE will spell it correctly. You can click on a constant definition and see all its uses. So I
started updating all my shipping statuses using `Shipping` class status constants. Then I started updating all my
machine statuses using a `Machine` class status constant.

And that's when I found it. I had been running a query looking for a machine status of `en route`, but machines didn't
have that status. The shipment had the `en route` status, and the machine wouldn't have a status until the shipment was
`delivered.`

The proper use of a class constant, or even an Enum in today's code, would have told me that searching a machine table's
status field for `Shipping::EN_ROUTE` would not be the correct search term. However, since it was a bare string
`en route`, and the `en route` status existed (elsewhere) it looked fine to my eyes **every single time**. The perfect
code was thwarted by a bare string that was correct, just not where it was.

And that's why I hate bare strings.
