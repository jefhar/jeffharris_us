---
title: Mass Effect Shepard Generator
date: October 9, 2019
tags: [PHP, React]
---
- [Gitlab Source](https://gitlab.com/jefhar/mestarter)
- [Web Deployment](https://jefhar.gitlab.io/mestarter)
## Overview
Mass Effect, the 2007 Bioware video game, starts by asking the player to create his or her own character.

Sometimes, a player just needs random choices. This page pulls an data from an API and creates a page
with the random choices for the user to enter.

The API is vanilla PHP, built in the [/api-src](https://gitlab.com/jefhar/mestarter/tree/master/api-src)
folder. On each push to the Master git branch, GitLab's CI/CD runner pushes a copy of the repository
to the API server, refreshes composer dependencies and updates the `document_root` directory for
zero-downtime deployment.

After the PHP deployment to the API server, the CI/CD runner creates a production build of the React
front end, and pushes it to a [GitLab](https://jefhar.gitlab.io/mestarter) project page.

### Code
{% include icon-gitlab.html username=site.gitlab_username %} You can find the source code for
Mass Effect Shepard Generator at
[{% include icon-gitlab.html username=site.gitlab_username %}/mestarter](https://gitlab.com/jefhar/mestarter).
