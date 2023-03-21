---
layout: post
title: Zero Downtime Deployment - Introduction
category: "Zero-Downtime"
tags:

- Blue
- CLI
- Docker
- Envoy
- GitLab
- Green
- Laravel

---
Zero Downtime deployment with Laravel Envoy, GitLab, and Docker.

My understanding of one part of the book _Extreme Programming Explained:
Embrace Change, 2nd Edition (The XP Series)_, Kent Beck with Cynthia Andres
says that you should have automated deployment of a project within a week of
starting it. I can't find the quote right now, so I might have misconstrued
it, or skipped something. Maybe it was talking about completing your
projects during the sprint and not having roll-over, but either way,
setting up your brand-new Laravel system for zero-downtime blue/green
deployments in both staging and production environments is a task that every
developer should strive for.

At the beginning of your project, it hasn't been launched, so it has zero
traffic and zero revenue. If you have an established site with plenty of
traffic and plenty of revenue to cover costs, then by all means use Laravel
Forge, Laravel Envoy, or some other managed service. At some point,
your site will be successful, and you will need to expand. Cross that bridge
when you get to it, not before; you might be crossing the wrong
bridge.

## Project Assumptions

Although we don't want to cross any bridges before we get to them because
[YAGNI](https://www.youtube.com/watch?v=f4QShF42c6E&t=13999s), some
requirements are common to many projects. Each project has a name, and I
will assume that using `potato` for a project name will be easy enough for
you to substitute your own project name throughout this how-to.

### The Requirements

This setup assumes that the project needs persistent mysql and redis
databases, a staging environment, and a production environment, both
environments with zero-downtime deployment. They will all be on the same
logical server, and they won't conflict with each other.

### The Solution

Dockerized blue-green deployments behind Traefik. The deployment will be
automated by Laravel Envoy, triggered by GitLab's CI/CD environment. When a
merge request is merged into the `development` branch, GitLab will run tests
and deploy to the staging environment. When `development` is merged into the
`main`/`master`/`releases`/`production` branch, Gitlab will run tests and
deploy to the production environment.

The server only needs one instance of mysql, with two databases; one for
`staging`, the other for `production`. Remember that if you need an extra
database connection in the future, you can add one, but you probably don't
need the complexity for a green-field project. The connection details are
defined in the `DB_*` keys of your `.env` files, so the data can be kept
separate. Likewise, the server only needs one instance of redis. Redis allows up
to 16 databases, so they can be kept separate using the `REDIS_DB`
and `REDIS_CACHE_DB` keys of your `.env` files, or by the single `REDIS_PREFIX`
key. Or both. It's your setup, but do you _really_ need it right now?

### Keeping things separated but connected

Traefik will be looking for containers in the `web` network. Once an
nginx server is added to the `web` network, traefik will perform its magic and
pass web traffic to the new container. That nginx container is also part of
a new network that includes the `php-fpm` container. In turn, the `php-fpm`
container needs to be on the same network as the mysql and redis containers.
In order to keep traffic away from the new server, we will install them from
the bottom up.

The persistent mysql and redis containers will be running in a `potato_common`
network. When the blue-staging environment is deployed, it will create
a `php-fpm` container. The `php-fpm` container will be added to
the `potato_common` network. It will also create and join to
a `potato_staging_blue` network. It will create the staging environment and
perform necessary migrations. Since the `php-fpm` container is not connected to
traefik's `web` network, he is just running in isolation.

However, since the new environment might touch the database, migrations need
to be planned accordingly. When you have enough traffic to your site, you
don't want to drop or rename a column before the code is pushed. Add a new
column in a migration and deploy. The next deployment will have a migration to  
copy the data from one column to the other, and use the new column in code.
A future deployment can drop the old column.

Once the new environment is installed, an nginx container will be brought to
life that connects to both `web` and `potato_staging_blue`. Traefik will see
the nginx container and start sending web traffic to the blue stack. Then we
pull down the green stack, and the users get the new deployment.

Let's get the server configured in [part
1](/zero-downtime/zero-downtime-deployment-1-server/). In [part
2](/zero-downtime/zero-downtime-deployment-2-gitlab/), we will get GitLab
configured, and in [part 3](/zero-downtime/zero-downtime-deployment-3-laravel/)
we 
will add the necessary code to the base Laravel installation and watch the 
automatic deployment.

1. [Configure the Server](/zero-downtime/2022-10-24-zero-downtime-deployment-1-server/)
2. [Configure GitLab](/zero-downtime/2022-10-25-zero-downtime-deployment-2-gitlab/)
3. [Add Code](/zero-downtime/2022-10-26-zero-downtime-deployment-3-laravel/)
