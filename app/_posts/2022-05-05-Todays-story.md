---
layout: post
category: development
tags:
- Story
- Development
title: Today's Story
---
So I've always been wanting to post things, but I feel I don't have anything 
to post. But I've been around long enough that I have plenty of stories, and 
a few of them might actually be interesting. 

Today is the story of how I started coding on the production server.

I started working at a company in 2006. It was a company that would make 
arrangements to pickup copy machines and office equipment when they came to 
end of lease or for repossession. When I came on, they were keeping track of 
everything using excel spreadsheets. Excel sheets to keep track of contacts, 
excel sheets to keep track of shipments, Excel sheets to keep track of 
inventory. It took a while to figure out the business rules before I was 
able to figure out how to design the inventory system.

I was a vacuum developer back then. That's a term I heard a while back for a 
single developer who codes alone. No one else to look at code reviews, no 
one else to bounce ideas off. Plenty of wrong ideas, and I found a lot of them.

This was back in the days when Symfony and CakePHP were getting started, but 
I didn't have any infrastructure, so I didn't know about them, and had to do 
everything from scratch. I started from a blank web page and just started 
coding sequentially what I needed to log in, to navigate through a menu, to 
see an entry form for adding pickup orders, adding notes, and eventually to 
inventory. My development "server" was a Dell Optiplex small form desktop 
computer. At the most, there would only be 10 concurrent users, so that 
machine would technically be enough for what we needed.

But before I got that far, I had enough for the collections team to see 
something, try out the interface, and let me know of any changes. So I 
created a few user accounts in the development database and let Amy and one of 
the bosses see the interface on the development server. The same morning, a 
new series of accounts from a new Leasing Company arrived. That boss then 
decreed that Amy would use the system as a trial for those new accounts. And 
the other collection representative wanted to use the system.

And that's how the development server became the production server and how I 
started coding directly on production. 
