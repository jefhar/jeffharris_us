---
layout: post
title: Testing in Tenancy For Laravel
tags:
    - Laravel
    - MultiTenancy
    - testing
Category: "Laravel Tips"
---

In my current side project, I am using the
[Tenancy for Laravel](https://tenancyforlaravel.com) package. Tenancy
effectively splits your Laravel application into two parts, all with the
same code base.

The Central Application mostly deals with creating and administering tenants;
it uses the main database of the application. A user registers with the
Central Application and creates a Tenant. This spins up a new database for
the Tenant, keeping each tenant separate from the next. This allows me to
create my Tenant Application from the standpoint that there is only a single
tenant.

This allows George Jones to become a client of Tenant #37, and also a client
of Tenant #83 without leaking data across Tenants. George's login to Tenant
#37 is in a separate database and has separate password hashing to George's
login for Tenant #83. Hopefully George used a different password, but that's
on George for not using a [password manager](https://bitwarden.com).

When testing a multi-tenant application, most of the testing involves the
Tenant Application. The best way of performing testing is by abstracting
away the necessary steps to enter the Tenant Application. First, a tenant
needs to be created. Tenancy for Laravel fires events when a tenant is
created to create the Tenant specific database and run migrations to initialize
that database. I created an extra Listener that duplicates the authenticated
user to the Tenancy database, so he will be able to use the new Tenant with
less friction. Each step adds to the complexity of a test.

#### How to setup a Test Class for a Tenant Application

The documentation for
[Tenancy For Laravel](https://tenancyforlaravel.com/docs/v3/testing) 
provides a simple test case, but I think we can do better than that.

The easiest thing is to create a new `TenantTestCase` class that makes sure
that there is a tenant for running tests in the Tenant Application.
Obviously, you should have your own tests in the Central Application that
ensure that your Tenant creation works as you expect, but that doesn't need
much extra setup. Tenancy gives this
[test solution](https://tenancyforlaravel.com/docs/v3/testing/#tenant-app).

I think we can do better. Let's extend the TestCase with a TenantTestCase.

{% highlight php linenos %}
<?php

declare(strict_types=1);

namespace Tests;

use App\Models\Domain;
use App\Models\Tenant;
use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Artisan;
use Stancl\Tenancy\Exceptions\TenantCouldNotBeIdentifiedById;

class TenantTestCase extends TestCase
{
    protected string $role = Role::ADMIN;
    protected Tenant $tenant;
    protected User $centralUser;
    protected User $user;

    /**
     * @throws TenantCouldNotBeIdentifiedById
     * @throws \Exception
     * @throws \Throwable
     */
    protected function setUp(): void
    {
        parent::setUp();
        $user = User::first();
        if (is_null($user) || is_null(optional(optional($user)->tenants)->first())) {
            echo 'refresh seeding';
            retry(2, static fn() => Artisan::call('migrate:fresh --seed'));
        }
        $this->centralUser = User::firstOrFail();

        /** @var Tenant $tenant */
        $tenant = $this->centralUser->tenants->first();
        $this->tenant = $tenant;

        tenancy()->initialize($this->tenant);
        $this->user = User::firstOrFail();
        $this->user->syncRoles($this->role);

        \DB::beginTransaction();
    }

    /**
     * @throws \Throwable
     */
    protected function tearDown(): void
    {
        \DB::rollBack();

        tenancy()->end();
        \DB::disconnect();
        parent::tearDown();
    }
}
{% endhighlight %}

#### The SetUp
I start the class with some protected class fields to help setting up each 
test. I can define a role in the concrete test class to set the User's Role. 
Just make sure to keep each Role testing in a separate class, then we keep 
track of each User and the Tenant.

Then the method looks for a User, and if there is no user, it refreshes the 
testing database and seeds it. Make sure that your seeder is creating a 
Central App user and a Tenant. It can be as simple as adding something like
`Provider::factory()->for(User::factory()->create())->create()`, just make 
sure it runs the Tenant Events to create and migrate the Tenant database. I 
wrap the seeder in a
[`retry()`](https://laravel.com/docs/10.x/helpers#method-retry) method just 
in case it decides to fail the first time. Then I pull the `centralUser` by 
using the `firstOrFail()` method so
[larastan](https://github.com/nunomaduro/larastan) doesn't complain that the 
object might be null.

Then I grab the Tenant for the User, and save it for later. When my 
application creates a new Tenant, it duplicates the User into the Tenant's 
Users, so I'll grab that and [sync]({% post_url 2023-04-19-reporting-your-sync-changes %})
the Role to remove the default `Role::ADMIN` if necessary.

Then wrap whatever will happen in the test in a database transaction so the 
database doesn't need to be refreshed and seeded after every test. Tenancy 
tells us that we
[can't use `RefreshDatabase`](https://tenancyforlaravel.com/docs/v3/testing/#tenant-app),
and we don't want to use `DatabaseMigrations` or `DatabaseTruncation` so we 
don't lose the Users or Tenants.

#### The TearDown
Simply, the `tearDown()` rolls back the database and ends the tenancy. I had 
an issue after my 151st test where I ran out of database connections, so I 
added the disconnect call. Then we pass to the `parent::tearDown()` and it's 
done.

Now when there is a test for the Tenant App, the test can extend the `TenantTestCase`
and the test is automatically in the tenancy with a user in the correct Role.

Ready, set, test!
