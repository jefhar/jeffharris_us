---
layout: post
title: A Woocommerce Replacement
categories: php
---

# Making some moola?

I have a WooCommerce site setup to sell some POD shirts fulfilled by Printful.
When I was setting it up, I was having problems syncing my products to my site.
The only thing that solved it was throwing more resources at it. Instead of 
using a small droplet until I build enough monthly sales to offset the cost 
of hosting and domain name, I have to use a more powerful droplet.

In case you're trying to diagnose this, the symptoms are during sync, the 
database crashes. During random checks of the site, the database crashes.

My immediate thoughts are either Woocommerce/WordPress tries to parse each
product as it arrives but can't keep up with the demand, which causes some
database overload. The other option is that Printful's bandwidth and servers are
so fast that Digital Ocean can't keep up with them. My hypothesis is that since
WordPress is built for anything, it can't handle everything. So let's try to
build a Laravel application that can handle a Printful store. Since we can make
a route prefix for the products, product categories, and other store items, it
should be fairly trivial to create route prefixes for any other static-ish pages
that are needed.

Printful has an API for creating your own store, but this is really designed 
for a whole package deal where you or your customers can design products on 
your website for fulfillment by Printful. That's a little more advanced than 
I want to do, so I'm going to emulate the WooCommerce Printful plugin. By 
doing this, we can connect as a WooCommerce store, and if the API matches, 
we just take care of the processing of products, and Printful will never 
know the difference.

## The Game Plan
I'm not going to do this all in one night, there are enough things that can 
go wrong with this and with life that it could very well take a year or more.
Also, one of the last things I want to do after coding all day is to come 
home and code more, although there is different motivation. Additionally, I 
have to write out everything I do.

Much like an epic, I'm going to break this out into different parts. First 
part will be to set up a very replicable server. Who knows, maybe I'll find 
a niche market and will need a server farm.

The second step would be to replicate the Printful authentication. It's been 
so long that I setup my initial Woo site that I forgot the steps. The good 
news is that servers are cheap and electrons are recyclable, so I can setup 
a new site just to check the steps. Once that's done, I'll create a product 
with a few different variant combinations to check what is sent. The sync 
from Printful can be captured, so testing can emulate it and we don't need 
to harass the Printful server. The WooCommerce Printful plugin will also be 
a resource. From there, I can look at database schema, and some minimal UI 
data, just to see what's what. After that, replicating most of the other 
Printful Plugin functionality, except ordering. Then I'll make a cart and 
send draft orders to Printful. At that point, there should be enough data to 
create a simple dashboard and connect Stripe.

That is as far out as I'm going to plan now; by the time I get that far 
there will be more user stories that come up.

## Homework for next time

This is for both you and I. Read
through [How To Use Traefik v2 as a Reverse Proxy for Docker Containers on Ubuntu 20.04
](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-v2-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04)
Up to Step 3. Technically, we could go through Step 3 just to make sure 
everything is working fine, but it's unnecessary.

See you next time.
