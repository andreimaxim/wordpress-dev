# wordpress-dev

This is a Docker image for developing and maintaining Wordpress sites.


## Usage

This docker image is supposed to be used as a base image for your Wordpress
projects, which means that its purpose is for you to be able to create a `Dockerfile`
that starts with this line:

```bash
FROM andreimaxim/wordpress-dev
```

Most likely, you will also need to add these lines in your Dockerfile
to have everything arranged nicely:

```bash
ARG WP_DOMAIN="example.com"
ENV APP_DIR="/srv/www/${WP_DOMAIN}"

# The replacement values contains some slashes which will normally
# break the sed format so using @ instead.
RUN sed -i -e"s@TEMPLATE@${WP_DOMAIN}@g" \
    /etc/nginx/sites-available/wordpress.conf \
  && sed -i -e"s@FOLDER@${APP_DIR}@g" \
    /etc/nginx/sites-available/wordpress.conf

RUN mkdir -p ${APP_DIR}

# Move the the application folder to perform all the following tasks.
WORKDIR ${APP_DIR}

# Ensure correct permissions.
RUN chown -R deploy:deploy ${APP_DIR}
```

This will automatically perform the setup for an environment based on Ubuntu 16.04 
(the latest LTS version) that contains the following packages:

* PHP 7.0
* PHP-FPM (running as user `deploy`)
* NGINX, with a configuration based on the [h5bp configs](https://github.com/h5bp/server-configs-nginx), running as user `deploy`

The reason behind those packages is that you can install them normally from the
official repository without importing various PPAs. Normally those packages are
slightly more stable and, in some cases, maintainers backport various bug fixes
so it's better to have that as a production environment.

Since this is a setup for Wordpress, chances are you'll be using Docker Compose
to manage this container and a MySQL container. This also allows you to specify
a domain name so the app is stored in the right folder (bonus points: you can
mirror this structure on your server and have multiple Wordpress instances on
the same server).

### SSL

The second thing you need to do is generate an SSL certificate and place it in 
a local folder (I used `config/docker/ssl`) and map it as a volume because 
Nginx is set to redirect from plain HTTP to HTTPS and it will fail unless it
has proper certificates.

Here's a minimal `docker-compose.yml` for a domain `example.com`:

```yml
version: '3.2'

services:

  app:
    build:
      context: .
      args:
        WP_DOMAIN: example.com
    volumes:
      - .:/srv/www/example.com
      - ./config/docker/ssl:/etc/nginx/ssl
```
### Hosts file

Finally, you need to tell your operating system that the domain that's being
served by this Wordpress instance is actually on `127.0.0.1`. On most operating
systems you need to edit the `hosts` file so it looks like this:

```
127.0.0.1   example.com
```

#### Why can't I use a different domain, like example.dev?

There are two main reasons for this (and if you have a better idea, a PR would
be quite interesting):

1. SSL. Using a different domain would require you to issue a certificate and use
  that one and you might have issues with various certificates in different browsers. With Let's Encrypt you can issue for free certificates.

2. Wordpress. I know you can have some scripts that automatically alter the database
  to change the domain and I'm sure that they work most of the time. However, it's a
  lot easier to simply dump the production data into your local database and have a
  100% identical copy of what's in production.

A third one is that I firmly believe that [Bedrock](https://roots.io/bedrock/) is the
best Wordpress boilerplate out there and this fits in nicely because it allows you to
update plugins and themes that might touch the DB locally and then deploy it to
production, maybe even as a container.


# Contributing

Discussions around the code or decisions are more than welcomed, PRs even more so!