---
categories: php, woocommerce
layout: post
title: A Woocommerce Replacement Part ][
---

# Shaving the Yak

If you
didn't [do the homework](https://jeffharris.us/php/A-Woocommerce-replacement/#homework-for-next-time)
last time, you are following along with me as I get my server setup before
starting to reverse engineer (and look at publicly available source code)
the Printful WooCommerce plugin.

Just to recap, WordPress is built for anything, and has trouble running
everything, so I am going to try something. A while back, I was setting up a
WordPress WooCommerce site to run a garment store powered by Printful. The least
powerful Digital Ocean droplet couldn't handle the product syncing operations,
so I have a hypothesis that the aged WordPress code tries to do too much in
series and crashes the database. If I'm right, I'm building a new garment store
that will become very much in demand, and I will be hailed as a hero to an
entire new generation of ecommerce wannabes who will want to send me all their
money in appreciation, and I can retire as independently wealthy within the
month. If not, hopefully I'll learn something and become better.

So head on over to your host (or use my affiliate link at Digital Ocean
https://m.do.co/c/cc1234dc66bf and receive $100, 60-day credit as soon as you
add a valid payment method to your account. And when you spend $25, I’ll also
receive a $25 credit with DigitalOcean, which will pay for a couple month's
hosting, so we both win) and set up a VPS.

Create a new project, and name it something awesome. I named mine
`woo-replacement`, so you know I'm really scratching my creative itch here. Then
click "Get started with a droplet." I'm going to use a Marketplace Application,
just to make startup go a bit quicker. Select
the `Docker 19.03. 12 on Ubuntu 20.04` app and the Shared CPU/Basic Plan.
Regular Intel with SSD, $5/month should be good enough for now. If I come to
find that this isn't enough, it would be evidence against my hypothesis. I can
always upgrade my droplet later, so if I need it, an upgrade is available. Skip
the block storage. I'll choose a datacenter region near me, and IPv6. I have
already uploaded some SSH public keys, so I'll add them. If this is your first
time, add one or more keys. I just need one droplet with the default host name.
I don't need backups for now, so I'll create the droplet. About a minute later,
my droplet is ready to go.

Now I'll assign a floating IP to that droplet so if I need to change droplets I
will have the same IP. Grab that floating IP and add a DNS record to a spare
domain I have lying around, and once dns has propagated,
`ssh root@<floating_ip>` and `adduser <myusername>` to set up a user for me to
use without breaking the system. Copy the ssh keys from my root user to my local
user, remembering to change the
owner. `usermod -aG sudo <myusername> && usermod -aG docker <myusername>` Log
out, and `ssh <floating_ip>` to re-enter the system as a regular user, and I'm
golden.

This isn't the first new server I've used, and I have a few particulars in the
way that I want things, so pause for a moment to standardize my server. Let's
make sure docker is ready, so fire up a `docker run jefhar/dirty-whale`
and see a whale with a "dirty" fortune, and Bob's your uncle.

```
 ______________________________________
/ The sex act is the funniest thing on \
| the face of this earth.              |
|                                      |
\ -- Diana Rigg                        /
 --------------------------------------
    \
     \
      \
                    ##        .
              ## ## ##       ==
           ## ## ## ##      ===
       /""""""""""""""""___/ ===
  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
       \______ o          __/
        \    \        __/
          \____\______/
```

Now on to the fun parts. Run bash command

```bash
sudo add-apt-repository ppa:ondrej/php && \
sudo add-apt-repository ppa:git-core/ppa && \
sudo apt-get update && \
sudo apt-get upgrade && \
sudo apt-get install -y screen nano apache2-utils make && \
sudo apt-get dist-upgrade
````
<_Jeopardy!_ theme plays for a while.> Restart the server and ssh back in as the
regular user. Create a directory for everything, so it isn't all in the root of
the user directory and `cd` into it.

## Step 1

Following step 1
of [How To Use Traefik v2 as a Reverse Proxy for Docker Containers on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-v2-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04)
it's finally time to configure Traefik. Create your `traefik.toml` and
`traefik_dynamic.toml` files as directed. At the bottom of `traefik_dynamic. toml`
add
```toml
[tls.options.default]
minVersion = "VersionTLS12"
curvePreferences = [ "secp521r1", "secp384r1" ]
sniStrict = true
```

## Step 2

Create a `Makefile`, making sure to use tabs to indent:

```makefile
traefik:
	docker network create web || echo "Docker network web already created."
	touch acme.json
	chmod 600 acme.json
	docker run -d \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v "$(CURDIR)/traefik.toml:/traefik.toml" \
		-v "$(CURDIR)/traefik_dynamic.toml:/traefik_dynamic.toml" \
		-v "$(CURDIR)/acme.json:/acme.json" \
		-p 80:80 \
		-p 443:443 \
		--network web \
		--name traefik \
		--restart unless-stopped \
		traefik:v2.2
```

Instead of running any of the commands listed in the linked tutorial, simply
`make` and traefik takes over. Give it a few minutes to settle, and browse to
your dashboard. My dashboard is using a Traefik Self-Signed Certificate, so it's
not as secure as I'd like it to be, but it will do for now. I have another site
running the same way that has a Lets-Encrypt certificate, so maybe it needs
something else. I'll come back to that in a bit.

## Step 3
I'm done with that tutorial, except for a reference to running traefik in a 
docker container. Time to get the WooCommerce replacement started. Before 
running the next bash commands, head on over to [getComposer]
(https://getcomposer.org/download/) and use the correct hash.

```bash
sudo apt-get install -y php8.0-cli php8.0-zip unzip php8.0-mbstring php8.0-xml
wget https://raw.githubusercontent.com/composer/getcomposer.org/b2ffe854401d063de8a3bf6b0811884243a381ba/web/installer -O - -q | php -- --quiet
./composer.phar self-update
sudo mv ./composer.phar /usr/local/bin/composer
composer create-project laravel/laravel woo-replacement
cd woo-replacement/
php artisan sail:install
```
Installing `mysql` and `redis` for now. Some of the other available services 
look interesting for later. Initialize a `git` repository, and push to your 
git* of choice.

I need to make a few changes and I'll be done for the night. First, add one 
line to `.env` file:
```dotenv
APP_PORT=8080
```

Create the following `docker-compose.override.yml`:

```yaml
version: "3"

networks:
  web:
    external: true
  sail:
    external: false
services:
  laravel.test:
    networks:
      - web
      - sail
    labels:
      - traefik.http.routers.web.rule=Host(`your_domain`, `www.your_domain`)
      - traefik.http.middlewares.web-https-redirect.redirectscheme.scheme=https
      - traefik.http.routers.web.middlewares=web-https-redirect
      - traefik.http.middlewares.web-www-https-redirect.redirectregex.regex=^http(?:s)?://(?:www.)your_domain/(.*)
      - traefik.http.middlewares.web-www-https-redirect.redirectregex.replacement=https://your_domain/$${1}
      - traefik.http.middlewares.web-www-https-redirect.redirectregex.permanent=true
      - traefik.http.routers.web.middlewares=web-www-https-redirect
      - traefik.http.routers.web.tls=true
      - traefik.http.routers.web.tls.certresolver=lets-encrypt
      - traefik.port=80
  mysql:
    labels:
      - traefik.enable=false
  redis:
    labels:
      - traefik.enable=false
```
Changing `your_domain` with your actual domain name.

Since people habitually type www for a domain, I want the www subdomain to be
redirected to the bare domain, although it could be the other way around. The
first three lines of labels attach the web router to the bare domain and the
www subdomain, and make sure that they are redirected to https. The next three
lines define a web-www-https-redirect middleware that uses the redirectregex to
search for a www subdomain and remove it. The double dollar sign in the
replacement escapes the dollar sign in the label. If you want to enforce www,
remove it from the `redirectregex.regex` and add it to the `redirectregex.
replacement`.

<img src="/assets/images/woo-replacement-webpage.png" width="400"
style="float: right; padding-left:8px;"/>Fire a `vendor/bin/sail up`, wait a second for the dust to settle, and load 
your domain name in the browser.
Now pop over to [SSL Labs](https://www.ssllabs.com/ssltest) and check your 
certificate report. At the time of this writing, my site is receiving an 'A' 
from SSL Labs.

### My Self-Signed Certificate
After a little troubleshooting, Traefik was generating a self-signed 
certificate instead of using a Let's Encrypt certificate due to a 
configuration issue. I had a wildcard CNAME record instead of a wildcard A 
record. Once I fixed that and restarted Traefik, Let's Encrypt was able to 
authenticate my domain and issue the required certificates. Ideally, I would 
like to use DNS authentication to issue wildcard certificates, but 
documentation in that area is lacking a bit. I run my own primary name 
server, and need to use an rfc2136 client. I guess there isn't a 
high-profile company using this technology, so the best documentation that I 
have found so far is outdated and vastly incomplete. I guess that will be a 
good topic for the future.
