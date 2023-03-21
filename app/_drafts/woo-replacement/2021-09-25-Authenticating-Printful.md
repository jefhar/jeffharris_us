---
layout: post
category: wooCommerce-replacement
tags:
  - Laravel
  - php
  - WooCommerce 
  - Traefik
title: Authenticating Printful
---

Now I'm going to try to get authenticated and connected to the Printful site.
Where and how the initial authentication happens is currently a mystery, but 
I'm here to reverse engineer the API.

I made a few changes to the Traefik configuration to watch the interactions 
with the Laravel installation. I added an `access.log` so I can see what 
comes into the server. In the `Makefile` I added a `touch` to the `access.
log` and attached a mount point into the Traefik container to watch. In the 
`traefik.toml` file, add a stanza to create the log file. Here is a patch of 
the existing configuration.

```patch
diff --git a/Makefile b/Makefile
index 7317a14..a67fffa 100644
--- a/Makefile
+++ b/Makefile
@@ -2,11 +2,13 @@ traefik:
        docker network create web || echo "Docker network web already created."
        touch acme.json
        chmod 600 acme.json
+       touch access.log
        docker run -d \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v "$(CURDIR)/traefik.toml:/traefik.toml" \
                -v "$(CURDIR)/traefik_dynamic.toml:/traefik_dynamic.toml" \
                -v "$(CURDIR)/acme.json:/acme.json" \
+               -v "$(CURDIR)/access.log:/access.log" \
                -p 80:80 \
                -p 443:443 \
                --network web \
diff --git a/traefik.toml b/traefik.toml
index cbe7565..ae21916 100644
--- a/traefik.toml
+++ b/traefik.toml
@@ -25,3 +25,6 @@

 [providers.file]
   filename = "traefik_dynamic.toml"
+
+[accessLog]
+  filePath = "access.log"
```

Restart the Traefik container, and `tail -f access.log` and watch those people
already trying to find whether I have a hackable `/wp-login.php` lol. Now login
to the Printful dashboard and before trying to connect to the WooCommerce 
site,
<iframe class="float-right" width="480" height="270"
src="https://www.youtube.com/embed/98JuvBEEBQQ?start=35"
title="YouTube video player" frameborder="0"
allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
allowfullscreen></iframe>
let's see what Wes from Printful has to say. A couple of things to note: I 
need to use real URL paths. Laravel routing will take care of that. I need a 
REST API. That's the "make it fully compatible with WooCommerce but better" 
that this entire series is about. The connection appears to be initiated by 
the Printful plugin.

This tells me that before external authentication, I need to start a 
dashboard with user authentication, and maybe think about
[Laravel Passport](https://laravel.com/docs/8.x/passport), but we'll see.

Before I start any of that, I'm going to look at the publicly available
[Printful plugin code](https://plugins.trac.wordpress.org/browser/printful-shipping-for-woocommerce/trunk?order=name)
to see if there are any hints how your site authenticates with the Printful back
end. Yes, that's a subversion repository: `brew install svn`. And a quick crash
course of the
[WordPress Plugin Handbook](https://developer.wordpress.org/plugins/)
just to see how things are supposed to be set up and arranged. BRB.

When Wes is connecting his WooCommerce site to Printful, he clicks a big 
blue button with the word "Connect." This is what it does:

```php
} else {
    ?><p class="connect-description"><?php esc_html_e('You\'re almost done! Just 2 more steps to have your WooCommerce store connected to Printful for automatic order fulfillment.', 'printful'); ?></p><?php
    $url = Printful_Base::get_printful_host() . 'dashboard/woocommerce/plugin-connect?website=' . urlencode( trailingslashit( get_home_url() ) ) . '&key=' . urlencode( $consumer_key ) . '&returnUrl=' . urlencode( get_admin_url( null,'admin.php?page=' . Printful_Admin::MENU_SLUG_DASHBOARD ) );
}

echo '<a href="' . esc_url($url) . '" class="button button-primary printful-connect-button ' . ( ! empty( $issues ) ? 'disabled' : '' ) . '" target="_blank">' . esc_html__('Connect', 'printful') . '</a>';
?>
```

It creates an URL
to `https://www.printful.com/dashboard/woocommerce/plugin-connect`
with a few query string variables.

- website: urlencoded string containing the base url of your
  site: `website=https%3A%2F%2F<your_site.com>%2F`
- key: a truncated consumer key that is used to authenticate to the Printful
  API. It is created by WooCommerce and found in the `woocommerce_api_keys`
  table.
- returnUrl: urlencoded string containing the return address. Once the user
  has (successfully?) connected, the browser will be directed here. In this
  case, it includes the admin
  path `https%3A%2F%2F<your_site.com>%2Fwp-admin%2Fadmin.php%3Fpage%3Dprintful-dashboard`

It seems that when you click the button, it sends you to the Printful site 
with your site address and a public key, where you authenticate and Printful 
stores the data and sends you back.

The WooCommerce code for creating an API key is quite simplistic. I imagined 
that a key would have some check digits or an algorithm to verify its 
usage. Nope, just a hash of a [random string](https://github.
com/woocommerce/woocommerce/blob/b19500728b4b292562afb65eb3a0c0f50d5859de/includes/class-wc-auth.php#L222) that is inserted into the database.

```php
// Created API keys.
$permissions     = in_array( $scope, array( 'read', 'write', 'read_write' ), true ) ? sanitize_text_field( $scope ) : 'read';
$consumer_key    = 'ck_' . wc_rand_hash();
$consumer_secret = 'cs_' . wc_rand_hash();

$wpdb->insert(
    $wpdb->prefix . 'woocommerce_api_keys',
	 array(
	    'user_id'         => $user->ID,
		'description'     => $description,
		'permissions'     => $permissions,
		'consumer_key'    => wc_api_hash( $consumer_key ),
		'consumer_secret' => $consumer_secret,
		'truncated_key'   => substr( $consumer_key, -7 ),
	),
	array( '%d', '%s', '%s', '%s', '%s', '%s',
);
```
