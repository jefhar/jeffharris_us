---
layout: post
title: Putting a Role on a Pivot Table
tags:
    - Laravel
    - Permissions
Category: "Laravel Tips"
---

As I mentioned [yesterday]({% post_url
2023-04-20-multi-tenancy-for-laravel-testing %}), my side project deals with
choruses and their trios, quartets, and other smaller performance groups. I
have some global Roles for the chorus members which can be attached to the
User model, just as you would expect. A problem arises when I want to attach
quartet roles to members.

The chorus has a few quartets, and user George Jones is a member of Quartet
#1. He has a `Quartet Admin` role, and the other members of his chorus have
the `Quartet Member` role. When I run tests for the permissions, George
Jones has `Quartet Admin` roles and permissions, and a random member only
has the `Quartet Member` roles and permissions. Tests pass.

Now suppose use George Jones is also a member of Quartet 2, but he only has
the `Quartet Member` role for that quartet. I run tests to make sure that
George has no Admin permission, and tests fail. George has both `Quartet
Admin` and `Quartet Member` permissions. The permissions need to be placed
on the pivot table between users and quartets. Sounds simple, as long as the
pivot table also has an autoincrement field and an
[associated model](https://laravel.com/docs/10.x/eloquent-relationships#defining-custom-intermediate-table-models).
The Spatie package can associate the autoincrement field to a Role.

Until it's time to detach a user from a quartet.

```php
$quartet = Quartets::find(1);
$quartet->users()->sync([2, 3, 4, 5])

The attribute [id] either does not exist or was not retrieved for model [App\Models\QuartetMember].

/Users/jeff/Code/vendor/laravel/framework/src/Illuminate/Foundation/Testing/Concerns/InteractsWithDatabase.php:50
/Users/jeff/Code/tests/Feature/Providers/Quartets/UpdateQuartetActionTest.php:245
/Users/jeff/Code/vendor/laravel/framework/src/Illuminate/Foundation/Testing/TestCase.php:173
```

Behind the scenes, Laravel first takes the difference between the wanted users
and the currently attached users and attempts to remove the row from the
database. To remove a row, Laravel takes the individual keys and attempts to
remove that row: In this case assuming that we're removing User #1, it looks
for `['quartet_id' => 1, 'user_id' => 1]` and runs the `delete()` method on that
row. It works fine without an id column because databases are smart like that.

However, if you have the
[Spatie.be Laravel Permissions](https://spatie.be/docs/laravel-permission/v5/introduction)
package installed and have a Role on the pivot model, there is a slight problem.
When Laravel deletes the row, it throws a `deleting` event on the model. The
Spatie package attaches a listener on to a model with roles to remove the
`Role` and does the same for `Permission`s.

```php
public static function bootHasRoles()
{
    static::deleting(function ($model) {
        if (method_exists($model, 'isForceDeleting') && ! $model->isForceDeleting()) {
            return;
        }

        $teams = PermissionRegistrar::$teams;
        PermissionRegistrar::$teams = false;
        $model->roles()->detach();
        PermissionRegistrar::$teams = $teams;
    });
}
```

That listener requires the `->getKey()` of the pivot row. So now what? We can
create our own listener on the pivot model to `refresh()` the model, and
Eloquent will fill in the missing model attributes, most importantly the `id`
field. So let's try adding
a [listener](https://laravel.com/docs/10.x/eloquent#events-using-closures)
on the pivot model:

```php
protected static function booted(): void
{
    static::deleting(static function (QuartetMember $quartetMember) {
        $quartetMember->refresh();
    });
}
```

Run tests, and again, they fail. When a
[model boots](https://github.com/laravel/framework/blob/10.x/src/Illuminate/Database/Eloquent/Model.php#L249)
, it runs a series of boot methods.

```php
protected function bootIfNotBooted()
{
    if (! isset(static::$booted[static::class])) {
        static::$booted[static::class] = true;

        $this->fireModelEvent('booting', false);

        static::booting();
        static::boot();
        static::booted();

        $this->fireModelEvent('booted', false);
    }
}
```

The `static::boot()` method reads the `bootHasRoles()` method from
the `HasRoles` trait and sets an event listener for the model's `deleting`
event. Then, in the `static::booted()` method, another `deleting` event listener
is registered. Listeners run in the order they are registered, so they will run
in the opposite order that we want. The solution is to move the listener
to `refresh()` the model into `static::boot()`, then call the `parent::boot()`
after the listener is registered. Alternatively, it can be placed
in `static::booting()` method if you think it belongs there.

```php
protected static function boot(): void
{
    // Put this here, so it runs before deleting listener defined in HasRoles.
    static::deleting(static function (QuartetMember $quartetMember) {
        $quartetMember->refresh();
    });
    
    parent::boot();
}
```

Now, the event listeners run in the correct order. The
model `['quartet_id' => 1, 'user_id' => 1]` is `refresh`ed, filling the
model's `id` field, allowing the Role to be detached. The only thing left is to
run permission checks on the pivot model instead of the user, and tests pass.

Happy Coding!
