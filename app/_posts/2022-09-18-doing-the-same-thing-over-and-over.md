---
layout: post
title: Doing the same thing over and over
tags: Makefile
category: "Code Snippets"
---
During development, sometimes you have to do the same things over and over
again. Every time you do it, you expect the same results, but sometimes your
fingers aren't on the correct keys, or your brain has gone on a temporary
vacation. You have to create your development environment,
although `docker-compose` encapsulates that for us. I find it handy to jump into
a shell running in the development container. Honestly, who wants to
type `docker compose exec php-fpm bash -c "/usr/bin/php artisan tinker"` more
than once a
month?

<aside><figure><p>"Insanity is doing the same thing over and over again and expecting different results."</p><figcaption> — <cite>not</cite> Albert Einstein</figcaption></figure></aside>

And building a `Jekyll` blog just for development? Who can remember all those
letters in the same order every time?

For commands run from the host environment, the solution is
a <strong>`Makefile`</strong>. Instead of remembering all the switches and
format of the `docker` command, a simple `make build` is a lot easier to
remember and type.

However, the `Makefile` doesn't have access to `bash` variables, so it makes it
a bit more difficult to mount the current `"${PWD}/"` directory into your
container. Since we want code to be portable, the development path cannot be
hard-coded into the `Makefile`. Well, it <em>could</em> but it shouldn't.

Instead of `"${PWD}/"`, we need to create
a [`Makefile` variable](https://web.mit.edu/gnu/doc/html/make_6.html), not a
shell variable. At the top of your `Makefile` add a variable
definition `ROOT_DIR:=$(shell dirname $(realpath$(lastword $(MAKEFILE_LIST))))`.
This defines a variable name `ROOT_DIR`. The variable is set using `:=` to a
simply expanded variable, that is a variable that is calculated once, like a
constant expression. The rest takes the `Makefile` and calculates its whole
path.[<sup>*</sup>](#caveat)

In the command list, we can use the `ROOT_DIR` just like any other shell
directory, by starting it with a `$` and wrapping it in
parentheses: `$(ROOT_DIR)`. At the time of writing, my `Makefile` looks like
this.

```makefile
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build:
	docker run --rm  -v "$(ROOT_DIR):/src" ruby:latest sh -c 'cd /src && bundle install && bundle exec jekyll build --watch'

run: build
	docker run -d -p 80:80 -v "$(ROOT_DIR)/_site:/usr/share/nginx/html" --name apache nginx:alpine

shell:
	docker run --rm -it -v "$(ROOT_DIR):/src" ruby:latest bash

test:
	gitlab-runner exec docker test

updategem:
	docker run --rm -v $(ROOT_DIR):/usr/src/app -w /usr/src/app ruby:latest bundle lock --update

update:
	docker run --rm -v "$(ROOT_DIR):/src" ruby:latest sh -c "cd /src/ && bundle config set path 'vendor/bundle' && bundle lock"

newpost:
	echo "---\nlayout: post\ntitle: title\n---" > app/_drafts/`date +%Y-%m-%d-`title_`date +%H_%M`.md
```

My `Makefile` also has a handy little command to create the stub of a new blog
post. Since I don't want to start a new post completely from scratch each time,
I add this just for a little reminder of how to post.

Here's another fun snippet from a [laravel](https://laravel.com) project running
in my own docker stack.

```makefile
tinker:
	docker compose exec php-fpm bash -c "/usr/bin/php artisan tinker"
```

Once you start adding commands to your `Makefile`, the sky is the limit. Just
remember to start all shell commands with a <strong>tab</strong>, not spaces. As
a <dfn title="Don't repeat yourself">[DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)</dfn>
concept, I'm even adding `make` commands in my `.gitlab-ci.yml` file just to
make sure that the CI commands are the same commands I expect on the command
line. Well, technically, it's <dfn title="Write everything twice">WET</dfn>, but
the duplication has been refactored into a single `make` command.

#### Caveat

<div class="alert alert-warning">
It is possible when using `make` as a build system for compiled applications, that a `Makefile` includes another `Makefile`. In this instance, each `Makefile` is appended to the end of `MAKEFILE_LIST`, and you may not be calculating the correct directory. 
</div>
