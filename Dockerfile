# This Dockerfile is supposed to create a replica of the server used to deploy
# the Wordpress site.
#
# Unfortunately, a lot of Docker images available on the Docker Hub are using
# custom builds of PHP or Nginx and not those that you might normally install
# on an Ubuntu server so we have to start from scratch.
FROM ubuntu:16.04

# Create a non-root user
RUN groupadd -r deploy \
    && useradd -m -r -g deploy deploy

ENV DEBIAN_FRONTEND noninteractive

RUN set -eux  \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
    php \
    php-cli \
    php-common \
    php-json \
    php-opcache \
    php-mysql \
    php-mbstring \
    php-mcrypt \
    php-zip \
    php-fpm \
    nginx \
    supervisor


# Setup folders and clean up default data
RUN mkdir -p /var/log/supervisor \
  && mkdir -p /run/php \
  && rm /etc/php/7.0/fpm/pool.d/www.conf \
  && rm /etc/nginx/sites-enabled/default

COPY config/supervisor/supervisord.conf /etc/supervisor/
COPY config/php-fpm/deploy.conf /etc/php/7.0/fpm/pool.d/

COPY config/nginx/nginx.conf /etc/nginx/
COPY config/nginx/sites-available/wordpress.conf \ 
  /etc/nginx/sites-available/

ARG WP_DOMAIN="example.com"
ENV APP_DIR="/srv/www/${WP_DOMAIN}"

# The replacement values contains some slashes which will normally
# break the sed format so using @ instead.
RUN sed -i -e"s@TEMPLATE@${WP_DOMAIN}@g" \
    /etc/nginx/sites-available/wordpress.conf \
  && sed -i -e"s@FOLDER@${APP_DIR}@g" \
    /etc/nginx/sites-available/wordpress.conf \
  && ln -s /etc/nginx/sites-available/wordpress.conf \
  /etc/nginx/sites-enabled/wordpress.conf


RUN mkdir -p ${APP_DIR}

# Move the the application folder to perform all the following tasks.
WORKDIR ${APP_DIR}

# Ensure correct permissions.
RUN chown -R deploy:deploy ${APP_DIR}

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]