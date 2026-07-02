FROM php:8.4-fpm-alpine AS builder

RUN apk add --no-cache \
    curl git libzip-dev zip unzip \
    oniguruma-dev autoconf g++ make

RUN docker-php-ext-install \
    pdo pdo_mysql zip opcache bcmath

RUN apk add --no-cache lz4-dev && \
    pecl install igbinary redis && \
    docker-php-ext-enable igbinary redis

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app
COPY composer.json composer.lock ./
COPY . .
RUN composer install --no-interaction --no-dev --optimize-autoloader --no-progress --no-scripts

FROM node:20-alpine AS assets

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM php:8.4-fpm-alpine AS dev

RUN apk add --no-cache \
    curl git libzip-dev zip unzip \
    oniguruma-dev autoconf g++ make nodejs npm

RUN docker-php-ext-install \
    pdo pdo_mysql zip opcache bcmath

RUN apk add --no-cache lz4-dev && \
    pecl install igbinary redis && \
    docker-php-ext-enable igbinary redis

RUN pecl install xdebug && docker-php-ext-enable xdebug

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/10-opcache.ini
COPY docker/php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/20-xdebug.ini

WORKDIR /app
COPY . .

RUN composer install --no-interaction --optimize-autoloader --no-progress
RUN npm ci

RUN mkdir -p storage/logs storage/framework/{sessions,views,cache} && \
    chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]

FROM php:8.4-fpm-alpine AS prod

RUN apk add --no-cache \
    curl libzip-dev oniguruma autoconf g++ make re2c zip unzip

RUN docker-php-ext-install \
    pdo pdo_mysql zip opcache bcmath

RUN apk add --no-cache lz4-dev && \
    pecl install igbinary redis && \
    docker-php-ext-enable igbinary redis

COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/10-opcache.ini

RUN addgroup -g 1000 laravel && \
    adduser -D -u 1000 -G laravel laravel

WORKDIR /app

COPY --from=builder /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build
COPY . .

RUN mkdir -p storage/logs storage/framework/{sessions,views,cache} && \
    chmod -R 777 storage bootstrap/cache

RUN chown -R laravel:laravel .

USER laravel

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9000/ping || exit 1

CMD ["php-fpm"]
