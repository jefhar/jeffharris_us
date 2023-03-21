---
layout: post
title: Money For Nothing
tags: Docker, Traefik, WordPress
category: "Traefik"
---

Let's see if we can figure out how to get some money for nothing. You're on your own
finding chicks for free; I have enough problems in that area right now.

Today, money for nothing is affiliate links and Print On Demand services.

We will connect a Printful account to a WooCommerce site from scratch, create some
garments, and wait for the sales to come rushing in. The genius part of Print On Demand
is that it requires no inventory until a product is sold. You don't need to have a
screen printer make 200 red shirts, only to find that your customers want them in blue.
You simply create a design, attach it to different sizes, colors, and styles of garment,
push it to a store, and wait for someone to purchase a shirt. They pay, the order goes
to Printful, who takes the size, color and style of your garment, prints your design on
it, and ships it directly to your customer.

## Getting Started
Let's get started with a <a href="https://m.do.co/c/cc1234dc66bf" title="Get $100 in
credit over 60 days.">Digital Ocean (affiliate link)</a> VPS. Start up a new Ubuntu
Basic Droplet and get it setup by following
[How To Use Traefik v2 as a Reverse Proxy for Docker Containers on Ubuntu 20.04
](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-v2-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04)
. At this point, you should have Traefik in front of a WordPress installation. Awesome.
This might be a good point to initialize a local git repository and commit everything.
If we keep the repository local, we don't really need to worry about committing secrets.
Adding files to git will make it easier to roll back changes if we find that something
didn't work the way it was expected to. I'm sure that's never happened for you, but it
has for me.

Before adding the files to git, add these lines to your `.gitignore` file:
```gitignore
.env
acme.json
mysql-data
```

Don't do too much inside your shiny new WordPress installation; we're going to tear it
all down and build it up again.

## Make it Easier
Create a `Makefile`. Note that the intentations MUST be tabs, not spaces.

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
		traefik:v2.2
```
Now if something happens, or you need to recover from `git`, you can simply run
`make traefik` from the command line and the traefik container will be back the way you
had it.

## Making Changes
Now, let's make some changes. I don't want to refer to my shop as a `blog`. In fact,
I am using a domain that I've had for a while for an email account, but haven't
really done anything with. I'm going to run my WooCommerce shop under the bare
domain, and I want to call the app `web`, since it will be the primary web
application on the domain. Let's make a quick perl substitution to get most of the
changes out of the way:

``` bash
perl -pi -e 's/blog/web/g' docker-compose.yml
```

Unfortunately, it also changed the subdomain, but we'll deal with that next.

### docker-compose.override.yml
What we *could* do to make more changes is to keep editing the `docker-compose.yml` file,
but where is the learning experience in that? I want to keep the `docker-compose.yml`
file mostly the same as the tutorial, for when future versions come out. It will be
easier to compare the original files with the updated files in a new tutorial and
hopefully an easier path to upgrade. To make our changes,
`docker-compose.override.yml` comes to the rescue.

The `docker-compose.override.yml` file will add to and override the settings in the
original `docker-compose.yml` file, which is why they named it `override`. Things don't
always need to be overly complicated.

Let's first setup the bare domain in the override file. Since people habitually
type `www` for a domain, I want the `www` subdomain to be redirected to the bare domain,
although it could be the other way around.

Create a `docker-compose.override.yml` file with the following:

```yaml
version: "3"

services:
  web:
    image: wordpress:5.5.1-php7.4-apache
    labels:
      - traefik.http.routers.web.rule=Host(`your_domain`, `www.your_domain`)
      - traefik.http.middlewares.web-https-redirect.redirectscheme.scheme=https
      - traefik.http.routers.web.middlewares=web-https-redirect
      - traefik.http.middlewares.web-www-https-redirect.redirectregex.regex=^http(?:s)?://(?:www.)your_domain/(.*)
      - traefik.http.middlewares.web-www-https-redirect.redirectregex.replacement=https://your_domain/$${1}
      - traefik.http.middlewares.web-www-https-redirect.redirectregex.permanent=true
      - traefik.http.routers.web.middlewares=web-www-https-redirect
```
The `image` replacement updates WordPress to the latest version. The first three lines
of labels reattach the `web` router to the bare domain and the `www` subdomain, and
make sure that they are redirected to https. The next three lines define a
`web-www-https-redirect` middleware that uses the `redirectregex` to search for a
`www` subdomain and remove it. The double dollar sign in the replacement escapes the 
dollar sign in the label.

And run `docker-compose up -d --remove-orphans` to load the new configuration. The 
`--remove-orphans` flag is needed here since we changed the name of the `blog` service
and it doesn't exist anymore. 

Now let's make some persistence changes. If I update my wordpress installation, I don't
want to lose my plugins, themes, or uploaded files. They can even be part of my git
repository. Let's make a few local directories and attach them inside the WordPress
Docker container. Run these on the command line:

```bash
mkdir wp-content
sudo chown www-data.www-data wp-content/
mkdir mysql-data
```

Add these to the `docker-compose.override.yml`
```yaml
    volumes:
      - ./wp-content:/var/www/html/wp-content
    restart: unless-stopped
  mysql:
    volumes:
      - ./mysql-data:/var/lib/mysql
    restart: unless-stopped
```
The 'v' of both **v**olumes should be in the same column as the 'l' of **l**abels, and
the 'm' of **m**ysql should be in the same column as the 'w' of **w**eb. While we're at
it, the containers should automatically restart should anything happen to them, unless
they are intentionally stopped.

There are more changes that should be made to make life easier, but we'll save those
for another day, we have some money to make. Restart the docker-compose stack, and let's
get WooCommerce and Printful installed:
`docker-compose down \
    && docker system prune -f \
    && docker volume prune -f \
    && docker-compose up -d`
If you get blocked mixed content, `export` the database passwords from the setup tutorial
and run the command again. Reinstall your database and update the plugins and themes. By
magic, the updated plugins are in the local directory, so they can be added to `git`.

Add the `WP Mail SMTP` plugin and get your outbound email hooked up. Then install the
WooCommerce plugin. Enter your address, and we will be operating in the "Fashion, apparel, and accessories"
industry with Physical products. Let's assume for now that we will have 11-100
products for display, and install the "recommended" plugins. For now, choose the
Boutique theme. We can always find another one or customize it later. Once installed,
WooCommerce wants a bunch of settings changed. Before we do that, install the
Printful Integration for WooCommerce plugin and activate it. Find the Printful link
in the sidebar and click it, then click the big Activate button. Then click the big
Approve button. Then create or login to your account, and press the "Connect" button.

In the Printful dashboard, click Stores, then in the WooCommerce row, click the gray
"Add Product" button. T-shirts are popular, so click the t-shirt link, and find the 
"Unisex Basic Softstyle T-Shirt | Gildan 64000" because, well why not? It has a badge
claiming that it's a best seller, so let's put a foot in the right direction. Add a
witty saying, or your own art on the shirt. Click "add to mockups" and choose some
mockups that will display on your product page in your store. If you want, modify the
description and/or Product title, and proceed to pricing. Set the prices you want to
charge for your new creation, and Submit to your store!
 
When the green bar finishes progressing, head back to your WordPress installation,
and check out the products.


## Resources
* <a href="https://m.do.co/c/cc1234dc66bf" title="Get $100 in
  credit over 60 days.">Digital Ocean (affiliate link)</a>
* [How To Use Traefik v2 as a Reverse Proxy for Docker Containers on Ubuntu 20.04
](https://www.digitalocean.com/community/tutorials/how-to-use-traefik-v2-as-a-reverse-proxy-for-docker-containers-on-ubuntu-20-04)
* [Making sense of Docker Compose overrides
](https://medium.com/it-dead-inside/making-sense-of-docker-compose-overrides-efb757460d64)
* [Choosing between www and non-www URLs
](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Choosing_between_www_and_non-www_URLs)
