---
layout: post
title: Shortcuts on the CLI
tags: CLI, Laravel
category: "Command Line"
---
I'm working on a project, over budget and late. To keep the development environment
exactly the same as the production environment, I am running a docker stack that I
originally generated over at [PHPDocker.io](https://phpdocker.io/generator). I have
one image running the php-fpm executor, and while I'm working, it is the window
into the Laravel engine. I've set the minimum PHP version to 7.4 to take
advantage of the [latest language features](https://www.php.net/migration74).

Since MacOS only comes stock with `PHP 7.3.11 (cli) (built: Feb 29 2020 02:50:36
) ( NTS )` I can't run `composer` or `php artisan` commands on my command line: `php
   7.3.11   dockerp/roject requires php (^7.4)`. No problem, just hop into
the dockerbox and make a non-critical change. I can hear some of you now, "No, stay
off the environment. You can make a change that won't be duplicatable." Yes, there
may be a temporary system dependency that isn't part of the image, but the chances
of really messing this up are low. And in the worst case, you rebuild the
image and re-install `composer` and `yarn` dependencies. That's one of the magical
things about `docker`. A few command lines will get you back to a pristine environment.

I've been updating my dependencies and refreshing the database, and testing CI scripts
long enough that I'm starting to get tired of typing in `docker run -it --rm -v"$
 (PWD):/application:delegated" node:14 bash` or
`docker run -it --rm -v"$(PWD):/application:delegated" project/php:7.4 bash` to grab
an interactive shell inside the container. And it's always the same, but it's
different. The variable in what to type is the container name. Simple. If I can
make this run a command, I want my command to be named `run`. I can pass to it the
name of the image, so I might `run ubuntu:bionic` or `run phpdockerio/php74-fpm:latest`.
 
Let's check to see if `run` is taken:

{% highlight shell %}
$ type run 
bash: type: run: not found
{% endhighlight %}
Good. It's available. I will put my file in my `~/bin/` folder so it will be in my path.
You might need to create it though, so `$ mkdir ~/bin` will make the directory. If
you did create the folder, it might not be in your `$PATH` yet. I have seen some
shell setup scripts check for the existence of `~/bin` before adding it to your
path. If it's not in your path, open another terminal or console. I need to create
a file, so I'll use my handy `vi ~/bin/run`. Actually, I'll use `nano`, but
whatever you want. The file will have the following lines:

{% highlight shell linenos %}
#!/bin/bash
docker run -it --rm -v"$(PWD):/application:delegated" $1 bash
{% endhighlight %}

The first line, the `hashbang` identifies the application that will be used to parse
this file. For a simple one-line script, or the "copy, move, rename" scripts you
hear so much about don't need a `hashbang`, the script will be run in whatever
shell you're currently using, whether it be `sh`, `bash`, `zsh`, or any of the
shells available. However, it doesn't hurt to be this specific. There are
differences between some commands in different shells, but we probably won't see
any today. However, if you ever do find that difference, you will have a
repeatable way of predetermining the result. The second line is the command
that is run when I enter `run` with the image name substituted in the command
by the `$1`: the first program argument. If I ever decide I need another
argument, I can substitute it with a `$2`. I made the `$pwd` variable lower case so I
can use the same command on linux or mac. One of them is quite case sensitive, the other
not so much.
 
Save and exit the file, and let's give it a whirl. Remember that if you didn't
restart your shell, this would be a good time to do it. We'll wait for you. The
reason we placed it in `~/bin` is that the directory is automatically searched when
a command is entered from the command line. You can view it by `echo $PATH` to see
the hierarchy. Whichever file is found first is used. The highest priority
directories for system commands appear first in the `$PATH` string. Then its
followed by utilities, and your home and other specific directories. In most cases,
unless you know what you're doing, save your files in `~/bin`. It is the only
directory that you have full executable privileges, and no one else but the
system god can write to. Got your new terminal open yet?

{% highlight shell %}
$ run ubuntu:latest
zsh: permission denied: run
{% endhighlight %}
So what happened to "it's in your path?" It's there, the error command tells us
exactly that: `permission denied`. Well that makes sense, where do you think writing
a file would make it executable? I need to apply permissions to the file to allow
it to be a series of commands to be run by the system. obviously, typing `chmod
` more than twice would make it worthwhile to shortening that command. I need a
`cx` command to `chmod +x`. I've already typed it twice, and I'm sick of it. I
also have a hangnail on my index finger. Damn quarantine. I'm
going to `nano ~/bin/cx`. Feel free to use `vi` or `pico` if you want. lol
 
{% highlight shell linenos %}
#!/bin/bash
chmod +x $1
{% endhighlight %}
Again, defining the interpreter with the `hashbang`, this will call `chmod +x`
(that's two more times) with the first argument after `cx` (so much easier). Now I have a
command to make a command executable. Except it's not executable. Here's how I fix
that:
{% highlight shell %}
$ sh ~/bin/cx ~/bin/cx
{% endhighlight %}
And boom. I use the `sh` shell to run the `~/bin/cx` command on `~/bin/cx`. Since
`~/bin/cx` is the first argument sent to `~/bin/cx`, `~/bin/cx` will be passed to
`chmod +x` giving it the privilege it needs to become executable. To prove it:

{% highlight shell %}
$ cx ~/bin/run
{% endhighlight %}
No news is good news, so we know the command ran. Now I can do something as wacky as 
{% highlight shell %}
$ cd ~/bin; run ubuntu:latest
root@15531bbe4ff5:/# cd /application
root@15531bbe4ff5:/application# ls -ltra
total 2372
-rwxrwxrwx 1 root root     81 Nov 27  2016 lilypond
-rwxrwxrwx 1 root root     113 May 19  2017 startsocat
-rwxrwxrwx 1 root root  243262 Jun  7  2017 dateTimeZoneData.php
-rwxr-xr-x 1 root root 1936645 Mar  4 21:00 composer
-rwxr-xr-x 1 root root      75 May 27 04:30 run
-rwxr-xr-x 1 root root      24 May 27 04:30 cx
drwxrwxrwx 8 root root     256 May 27 04:30 .
drwxr-xr-x 1 root root    4096 May 27 04:31 ..
root@15531bbe4ff5:/application# 
{% endhighlight %}
And there is my `~/bin` directory attached to `/application` in an `ubuntu:latest
` container. Awesome. Exit the container and enter `$ cd -` at the command prompt to
go back where you came from, presumably a project root. I whip out my new toy and

{% highlight shell %}
$ run node:14
root@3fce8c00b8cf:/# cd /application/
root@3fce8c00b8cf:/application# yarn install
yarn install v1.22.4
[1/4] Resolving packages...
[2/4] Fetching packages...
{% endhighlight %}
![Alt text](https://i3.kym-cdn.com/photos/images/original/000/401/463/ee2.png)
{% highlight shell %}
info "fsevents@1.2.13" is an optional dependency and failed compatibility check. Excluding it from installation.
[3/4] Linking dependencies...
[4/4] Building fresh packages...
Done in 3724292.49s.
root@3fce8c00b8cf:/application# npm run dev

> @ dev /application
> npm run development


> @ development /application
> cross-env NODE_ENV=development node_modules/webpack/bin/webpack.js --progress --hide-modules --config=node_modules/laravel-mix/setup/webpack.config.js
98% after emitting SizeLimitsPlugin

 DONE  Compiled successfully in 32504ms                                                                                              4:33:13 PM

                                                                                              Asset      Size   Chunks             Chunk Names
                                                                                       /css/app.css   253 KiB  /js/app  [emitted]  /js/app
                                                                                         /js/app.js   8.1 MiB  /js/app  [emitted]  /js/app
   fonts/vendor/@fortawesome/fontawesome-free/webfa-brands-400.eot?c1868c9545d2de1cf8488f1dadd8c9d0   130 KiB           [emitted]  
   fonts/vendor/@fortawesome/fontawesome-free/webfa-brands-400.svg?0cb5a5c0d251c109458c85c6afeffbaa   699 KiB           [emitted]  
   fonts/vendor/@fortawesome/fontawesome-free/webfa-brands-400.ttf?13685372945d816a2b474fc082fd9aaa   130 KiB           [emitted]  
 fonts/vendor/@fortawesome/fontawesome-free/webfa-brands-400.woff2?a06da7f0950f9dd366fc9db9d56d618a  74.8 KiB           [emitted]  
  fonts/vendor/@fortawesome/fontawesome-free/webfa-brands-400.woff?ec3cfddedb8bebd2d7a3fdf511f7c1cc  87.7 KiB           [emitted]  
  fonts/vendor/@fortawesome/fontawesome-free/webfa-regular-400.eot?261d666b0147c6c5cda07265f98b8f8c  33.6 KiB           [emitted]  
  fonts/vendor/@fortawesome/fontawesome-free/webfa-regular-400.svg?89ffa3aba80d30ee0a9371b25c968bbb   141 KiB           [emitted]  
  fonts/vendor/@fortawesome/fontawesome-free/webfa-regular-400.ttf?db78b9359171f24936b16d84f63af378  33.3 KiB           [emitted]  
fonts/vendor/@fortawesome/fontawesome-free/webfa-regular-400.woff2?c20b5b7362d8d7bb7eddf94344ace33e  13.3 KiB           [emitted]  
 fonts/vendor/@fortawesome/fontawesome-free/webfa-regular-400.woff?f89ea91ecd1ca2db7e09baa2c4b156d1  16.4 KiB           [emitted]  
    fonts/vendor/@fortawesome/fontawesome-free/webfa-solid-900.eot?a0369ea57eb6d3843d6474c035111f29   198 KiB           [emitted]  
    fonts/vendor/@fortawesome/fontawesome-free/webfa-solid-900.svg?ec763292e583294612f124c0b0def500   876 KiB           [emitted]  
    fonts/vendor/@fortawesome/fontawesome-free/webfa-solid-900.ttf?1ab236ed440ee51810c56bd16628aef0   198 KiB           [emitted]  
  fonts/vendor/@fortawesome/fontawesome-free/webfa-solid-900.woff2?b15db15f746f29ffa02638cb455b8ec0  77.6 KiB           [emitted]  
   fonts/vendor/@fortawesome/fontawesome-free/webfa-solid-900.woff?bea989e82b07e9687c26fc58a4805021   101 KiB           [emitted]  
{% endhighlight %}
Now I can enter a docker environment that is identical to the deployment environment
, and manually run commands that are automated for deployment with a minimal of key
presses. Unfortunately for JavaScript developing, an `npm run watch` in this container will
 not proxy the `docker-compose` web server, because they are on different networks.
 I'll fix that deficiency in an upcoming post. 
 
 However, it works with any image. This blog is powered by
[Jekyll](https://jekyllrb.com/) so I can view it locally when writing, by first
creating a webserver:
`docker run -d -p 80:80 -v"$(pwd)/_site:/usr/share/nginx/html" nginx:alpine`.
Then, I can have Jekyll watch for file changes, so I can see it at <http://localhost:80> and
make sure it looks good before I deploy it.

{% highlight shell %}
$ run ruby:latest
  root@edfd0db95fa8:/# cd /application ; bundle config set path '/vendor/bundle'; bundle install; bundle exec jekyll build --watch
  Fetching gem metadata from https://rubygems.org/.........
  Fetching public_suffix 4.0.5
  Installing public_suffix 4.0.5
  Fetching addressable 2.7.0
  Installing addressable 2.7.0
  Using bundler 2.1.4
  Fetching colorator 1.1.0
  Installing colorator 1.1.0
  .
  .
  .
  Bundle complete! 8 Gemfile dependencies, 34 gems now installed.
  Bundled gems are installed into `/vendor/bundle`
  Post-install message from i18n:
  .
  .
  .

                      done in 2.703 seconds.
   Auto-regeneration: enabled for 'app'

{% endhighlight %}

Hopefully this will help out someone as much as it helps me to write it. If this
helps, or you want to know more, reach out to me, or
[file an issue](https://gitlab.com/jefhar/jefhar.gitlab.io/-/issues).
