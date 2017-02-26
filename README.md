### Virtualmin now have [native FPM support](https://www.virtualmin.com/project/issues?text=php-fpm&projects=&status=Open&categories=All&order=created&sort=desc).
### As soon as official FPM support will become 100% workable I'll drop support of this module.


Virtualmin plugin for creating websites served by Nginx through PHP-FPM
Can be downloaded from install directory.

How to use:

1. Download and install module.
2. Go to "System Settings -> Features and Plugins" in your Virtualmin panel.
3. Check "Nginx PHP-FPM website" feature.
4. You may also configure feature by clicking appropriate link in actions column on the same page, however you'd better not mess with it as it has some reasonable defaults.
5. Go on and create new virtual server, don't forget to enable feature on domain creation.
6. After virtual server created you may change some settings by navigating to "Services -> Manage Nginx PHP-FPM website"

SSL support is working one way: it is either disabled or enabled and all HTTP requests are redirected to HTTPS.
All major browsers are planning to drop plain HTTP support so I think there's no reason to make this option more flexible.
Nginx TLS versions limited to 1.1 and 1.2 to prevent protocol downgrade attacks leading to vurnerabilities such as "poodle".
