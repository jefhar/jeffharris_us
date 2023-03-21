---
layout: post
title: Strengthening Security of WordPress Behind Traefik
tags: Docker, Traefik, Security
category: "Traefik"
---
In the [last post]({% post_url 2020-10-24-Money-For-Nothing %}), we setup a WordPress
site behind a Traefik front end. It is secured, and will get a boost from
the mighty Goog. But, does it really offer great security for our customers? If they
are making a purchase, we owe it to them to make sure we are as secure as possible, and
we're not even trying to keep stuff secret from the government. *Or are we...?* 🤫

Unfortunately, [SSL Labs](https://www.ssllabs.com/ssltest)
only gives the default install a B rating. <img src="/assets/images/sslLabs_before.png
" width="400"
style="float: right; padding-left:8px;"/> That's not bad, we are providing some
security, but we can easily do better.
[Observatory by Mozilla](https://observatory.mozilla.org/analyze.html) rates the safety
and security of the installation even worse.  The good news is that unless the site is
reverted to http, it can't get any worse.
 
## Increase security!
Let's get that A rating from SSL Labs. Add the following to the bottom of the 
`traefik_dynamic.toml`:
```toml
[tls.options.default]
minVersion = "VersionTLS12"
curvePreferences = [ "secp521r1", "secp384r1" ]
sniStrict = true
```
<img src="/assets/images/mozillaObservatory_before.png" width="400"
style="float: right; padding-left: 8px;"/>
and run `docker container restart traefik` on your command line and magically, we're
up to an A rating. The SSL security only measures the safety of the signal over the wire;
the HTTP headers that Mozilla Observatory look for keep our users safe from behavioral
activity.

Sure, we can still do better, and we don't even have any HTTP headers
for the browsers to keep people safe from behavior. The good news, however, is that
the `traefik_dynamic.toml` changes apply to the database admin and the monitor. Throw
your `db-admin` site into the SSL Labs checker and you should get the same results.

## But First
I have written these posts over a couple of days. Each time, I can't reload my WordPress
containers because I forgot to export the database password. So let's take care of never
needing to do that again. Docker's `.env` file comes to the rescue. HOWEVER, since
remembering what secrets you need to define is also a pain, we'll create a reminder
file, and we'll call it `.env.example`: (You didn't actually use
`secure_database_password` as your secure database password, did you? Of course not,
but put it here.)
```dotenv
DB_PASSWORD=secure_database_password
```
This file can be added to your git repository, since it doesn't actually (hopefully)
have your password. Now copy it: `cp .env.example .env` and edit the new `.env` file to
have your actual password. If you were following along, `.env` is already part of the 
`.gitignore` file, so it will already be ignored. Now to add the variables, add the
following lines to the `docker-compose.override.yml` file:
```yaml
services: # this is already there.
  web:    # So it this one
    environment:
      WORDPRESS_DB_PASSWORD: "${DB_PASSWORD}"
[...] # skip down aways
  mysql:  # find this line, and add
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_PASSWORD}"
```
If you remembered your password, fire off a `docker-compose up -d` on the command line
to refresh the affected containers, and you should be golden.

#### Resources
* [Traefik 2 - TLS Configuration (Rank A+ on SSLLabs)](https://tferdinand.net/en/traefik-2-tls-configuration/)
* [Environment variables in Compose
](https://docs.docker.com/compose/environment-variables/)
