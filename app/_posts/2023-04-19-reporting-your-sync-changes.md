---
layout: post
title: Reporting your Sync changes
tags:
    - Laravel
Category: "Laravel Tips"
---

A Laravel
[many-to-many](https://laravel.com/docs/10.x/eloquent-relationships#many-to-many)
relationship uses a pivot table to connect many models to many other models.
For example, a User might have many roles; he can be an `Author`, and an
`Editor`. Likewise, a role of `Author` can have multiple users.

#### Creating or Removing a Single Relation

One side of the relationship can be attached to the other by using the
`attach()` method on the relationship method, and it can be removed from the 
relationship by using the `detach()` method.

```php
use App\Models\Role;
use App\Models\User;
 
$user = User::find(1);

$oldRole = Role::whereName(Role::EDITOR)->sole();
$newRole = Role::whereName(Role::AUTHOR)->sole(); 

$user->roles()->detach($oldRole);
$user->roles()->attach($newRole);
```

#### Updating a  Relation List

Or you can synchronize a list of roles in one fell swoop with the `sync()`
method. It will remove all relations not listed, and make sure that any
listed relations are added.

```php
// Using the same $user that has `Author` and doesn't have `Editor`, but
// it might have other roles attached that we don't want him to have. 

$roles = Role::whereIn(
    'name',
    [Role::AUTHOR, Role::MANAGER, Role::DEPARTMENT_HEAD]
)
->get();
$user->roles()->sync($roles);
```

We can also have extra data on the pivot table, perhaps we want to record
the user who changed the permission. We can send that data to the `sync()`
method with a larger array. This array needs the related model's key, which
is usually `id`, but it might `uuid`, or `ulid` or `hash_id`, so we can
future-proof ourselves by using the `getKey()` method on the model:

```php
$user->roles()->sync([
    $authorRole->getKey() => ['updated_by' => Auth::id()],
    $managerRole->getKey() => ['updated_by' => Auth::id()],
    $departmentHeadRole->getKey() => ['updated_by' => Auth::id()],
])
```

In this case, since all the extra data is the same, we can send it once and 
Eloquent will add it for us:

```php
use Illuminate\Support\Facades\Auth;

$user->roles()->syncWithPivotValues($roles, ['updated_by' => Auth::id()]);
```

#### Enhancing the user experience

So how do we know what changed? It might be a use case that with your change,
you send a [flash message](https://laravel.com/docs/10.x/session#flash-data)
to the user telling them that the changed user no longer has the role of `Super
Admin`, but now has the role `Manager`. We can do that by capturing the
return value of `sync()`.

The `sync()` method returns an array of arrays with three
keys: `attached`, `detached`, and `updated`, each one containing an array of
the affected relationships.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Today&#39;s Laravel Tip: a many-to-many relationship&#39;s sync() will return an array of the changes made.<br><br>In this example, User 82 is now attached to my model, User 57 is no longer attached, and a change was made to a pivot table attribute for User 54. <a href="https://t.co/thZaEoeNRU">pic.twitter.com/thZaEoeNRU</a></p>&mdash; Jeff Harris 🏆 (@jefhar70) <a href="https://twitter.com/jefhar70/status/1648351261752688642?ref_src=twsrc%5Etfw">April 18, 2023</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

I this specific use case, I am attaching users to smaller groups. Here we
see that my group now has a new attachment to User #82, is no longer
attached to User #57, and a pivot attribute has changed on the relationship
with User #54. Any existing relationships remain

With this data, I can create one or more flash messages telling the user of
these changes.

```php
$request->session()->flash('attached', 'Group now contains User(s) '
    . array_values($changes['attached']));
$request->session()->flash('detached', 'Group no longer contains User(s) '
    . array_values($changes['detached']));
```

Happy coding!
