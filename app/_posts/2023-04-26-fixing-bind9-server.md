---
layout: post
title: Fixing Bind Server
tags:
    - DNS
    - Bind
    - named
Category: "Fixing the Broke"
---

In my multi-tenant side project, I have a plan to allow my providers to
register an account for their chorus. They will then be able to forward a
subdomain from their chorus domain to my service. I'm running traefik on my
server to route my other domains to their respective services, while
allowing this project its own specialized domains. The how of dynamically
changing traefik's routing is for a different post, but I ran into an issue
last night during a deployment, that's not related to deployment.

As part of my traefik setup, I have a wildcard certificate on my staging and
deployment servers through [Let's encrypt](https://letsencrypt.org/). Let's
encrypt requires
a [DNS challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
for wildcard certificates, and I run my own
DNS server. I don't like to be limited to the records that your domain
registrar think you should have, but again, that's a topic for another
discussion.

When I initially set up my wildcard DNS, I manually configured it while
working through the documentation, and it worked just fine. I guess now it's
time for renewal, which alerted me to the error. My Bind9 server is dead.
That should be an easy fix, and I say that now, but I'm live-blogging as I
troubleshoot the issue.

```bind
# rndc start
rndc: connect failed: 127.0.0.1#953: connection refused
```

Nope. How about restarting "the Linux way:"

```log
# systemctl start named
Job for named.service failed because the control process exited with error code.
See "systemctl status named.service" and "journalctl -xeu named.service" for details.

# systemctl status named.service
× named.service - BIND Domain Name Server
     Loaded: loaded (/lib/systemd/system/named.service; enabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Wed 2023-04-26 12:35:34 EDT; 1min 10s ago
       Docs: man:named(8)
    Process: 73147 ExecStart=/usr/sbin/named $OPTIONS (code=exited, status=1/FAILURE)
        CPU: 15ms

Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Scheduled restart job, restart counte>
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: Stopped BIND Domain Name Server.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Start request repeated too quickly.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Failed with result 'exit-code'.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: Failed to start BIND Domain Name Server.

# journalctl -xeu named.service
Apr 26 12:35:34 dns.myhostingaccount.info named[73148]: loading configuration: failure
Apr 26 12:35:34 dns.myhostingaccount.info named[73148]: exiting (due to fatal error)
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Control process exited, code=exited, >
░░ Subject: Unit process exited
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ An ExecStart= process belonging to unit named.service has exited.
░░
░░ The process' exit code is 'exited' and its exit status is 1.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Failed with result 'exit-code'.
░░ Subject: Unit failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ The unit named.service has entered the 'failed' state with result 'exit-code'.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: Failed to start BIND Domain Name Server.
░░ Subject: A start job for unit named.service has failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ A start job for unit named.service has finished with a failure.
░░
░░ The job identifier is 4541 and the job result is failed.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Scheduled restart job, restart counte>
░░ Subject: Automatic restarting of a unit has been scheduled
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ Automatic restarting of the unit named.service has been scheduled, as the result for
░░ the configured Restart= setting for the unit.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: Stopped BIND Domain Name Server.
░░ Subject: A stop job for unit named.service has finished
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ A stop job for unit named.service has finished.
░░
░░ The job identifier is 4618 and the job result is done.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Start request repeated too quickly.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: named.service: Failed with result 'exit-code'.
░░ Subject: Unit failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ The unit named.service has entered the 'failed' state with result 'exit-code'.
Apr 26 12:35:34 dns.myhostingaccount.info systemd[1]: Failed to start BIND Domain Name Server.
░░ Subject: A start job for unit named.service has failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░
░░ A start job for unit named.service has finished with a failure.
░░
░░ The job identifier is 4618 and the job result is failed.
```

Sweet. Bind can't start, and the only thing it can tell me is that it can't
start. So now I'll retry `# systemctl start named` and look at the syslog.
Starting BIND 9.18.12-0ubuntu0.22.04.1-Ubuntu, running on my server, built
with this, these algorithms, and boom:

```log
Apr 26 12:41:43 dns named[73708]: /etc/bind/named.conf.options:62: 
'inline-signing yes;' must also be configured explicitly for zones using dnssec-policy without a configured 'allow-update' or 'update-policy'. See https://kb.isc.org/docs/dnssec-policy-requires-dynamic-dns-or-inline-signing
Apr 26 12:41:43 dns named[73708]: message repeated 19 times: [ /etc/bind/named.conf.options:62: 'inline-signing yes;' must also be configured explicitly for zones using dnssec-policy without a configured 'allow-update' or 'update-policy'. See https://kb.isc.org/docs/dnssec-policy-requires-dynamic-dns-or-inline-signing]
```

Now there we
go. [The fine doc page](https://kb.isc.org/docs/dnssec-policy-requires-dynamic-dns-or-inline-signing)
says "all that you need to do is to add an additional option to the
configuration of each zone that is logging the error message." That sounds 
simple enough, except it doesn't say which zones are logging the error message.

The message was repeated 19 times. I have 18 zones in my `named.conf.local` 
file, two of which are set for dynamic updates. Then there are the four
pre-defined zones in `named.conf.default-zones`. If I have 18 zones, two of 
which don't throw an error, and the other four zones which are throwing an 
error, that is 20 error messages: the first one and the repeated 19 times.

That tells me that one of my zones that is set for dnssec without updates 
needs the `inline-signing yes;` option. I'll test by adding it to one zone 
and restart.

```log
Apr 26 13:12:31 dns named[76795]: /etc/bind/named.conf.options:62: 'inline-signing yes;' must also be configured explicitly for zones using dnssec-policy without a configured 'allow-update' or 'update-policy'. See https://kb.isc.org/docs/dnssec-policy-requires-dynamic-dns-or-inline-signing
Apr 26 13:12:31 dns named[76795]: message repeated 18 times: [ /etc/bind/named.conf.options:62: 'inline-signing yes;' must also be configured explicitly for zones using dnssec-policy without a configured 'allow-update'
```

Error repeated 18 times. It looks like my hypothesis works, but now the 
question is "since I'm adding a `dnssec-policy` globally, can I add 
`inline-signing` globally also?". I add it to the
`options{inline-signing yes; }`, and I get &lt;sadTuba.mp3>
```log
Apr 26 13:14:07 dns named[76872]: /etc/bind/named.conf.options:63: unknown option 'inline-signing'
```
How about adding it to my dnssec-policy? Nope, doesn't like that, either. 
It's just another thing to add to each and every zone. Restart `named` and 
it's working!

```bash
# rndc status
version: BIND 9.18.12-0ubuntu0.22.04.1-Ubuntu (Extended Support Version) <id:>
running on dns.myhostingaccount.info: Linux x86_64 5.15.0-70-generic #77-Ubuntu SMP Tue Mar 21 14:02:37 UTC 2023
boot time: Wed, 26 Apr 2023 17:26:57 GMT
last configured: Wed, 26 Apr 2023 17:26:57 GMT
configuration file: /etc/bind/named.conf
...
```

So there I go. An error that was silently ignored now causes complete 
failure and requires you to fix it, and now it's working fine.
