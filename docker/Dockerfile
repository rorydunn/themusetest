FROM php:7.2-apache

RUN apt-get update && apt-get install -y libmcrypt-dev \
    mariadb-client libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-install pdo_mysql

WORKDIR /var/www/html

RUN touch /var/www/html/index.php
RUN echo '<?php echo "Hello Muse Employees!" ?>' > index.php
