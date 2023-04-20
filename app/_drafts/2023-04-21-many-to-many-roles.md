---
layout: post
title: Putting a Role on a Pivot Table
tags:
    - Laravel
    - MultiTenancy
    - testing
Category: "Laravel Tips"
---

Without getting into too many details about my current side project, I am
using the [Tenancy for Laravel](https://tenancyforlaravel.com) package. Each
tenant is a different chorus, each with different users, each of whom has a
Role, managed by the Spatie package
[Laravel-permissions](https://spatie.be/docs/laravel-permission/v5/introduction).
I have an `administrator` role and a `manager` role, depending on whether a user
has write permissions to chorus information.

Just to add complexity, a chorus may be comprised of trios, quartets, or
other smaller performing units. For the sake of simplicity, I'm going to
call these subgroups quartets since my [chorus](https://goldstandardchorus.org)
has more quartets than other sized subgroups. In each quartet, I want
an `administrator` and a `member` Role, independent of other quartets and other
Roles. I have created a
[many-to-many]({% post_url 2023-04-19-reporting-your-sync-changes %})
relationship between users and the subgroups.

Awesome! I can give User #82 `manager` powers, and add him as a
`member` of Quartet #37, and that works as expected. Tests show that the
permissions for the Chorus do not allow the `manager` Role permission to
change the chorus information, and does not allow a `member` Role to change
the quartet information. Now the user joins another quartet, and is the 
quartet `administrator`. I run my tests, and they fail; the user now has 
`administrator` Role
