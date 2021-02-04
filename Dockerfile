FROM php:8.0.1-fpm-alpine3.13

WORKDIR /data/web

ADD php.ini /usr/local/etc/php/
ADD www.conf /usr/local/etc/php-fpm.d/
RUN chmod 777 /data/web/ -R

RUN apk add supervisor git bash openssl openssh
RUN apk add autoconf g++ make cmake pcre-dev re2c
RUN apk add linux-headers zlib-dev openssl-dev
RUN apk add libmcrypt-dev libxslt-dev
RUN apk add freetype freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev
RUN apk add libzip-dev
#RUN apk add nginx go nodejs

# install some extension
RUN docker-php-ext-install gd
#RUN docker-php-ext-install intl
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install sysvsem
RUN docker-php-ext-install zip
RUN pecl install igbinary && docker-php-ext-enable igbinary
  
# compile phalcon
#ENV PHALCON_VERSION=3.4.3
#RUN curl -fSL https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz #-o cphalcon.tar.gz \
#    && mkdir -p cphalcon \
#    && tar -xf cphalcon.tar.gz -C cphalcon --strip-components=1 \
#    && rm cphalcon.tar.gz \
#    && cd cphalcon/build \
#    && sh install \
#    && rm -rf cphalcon \
#    && docker-php-ext-enable phalcon

ENV MONGODB_VERSION=1.9.0
# compile mongodb extension
RUN set -xe \
    && curl -fSL http://pecl.php.net/get/mongodb-${MONGODB_VERSION}.tgz -o mongodb.tar.gz \
    && mkdir -p /tmp/mongodb \
    && tar -xf mongodb.tar.gz -C /tmp/mongodb --strip-components=1 \
    && rm mongodb.tar.gz \
    && docker-php-ext-configure /tmp/mongodb --enable-mongodb \
    && docker-php-ext-install /tmp/mongodb \
    && rm -r /tmp/mongodb

ENV REDIS_VERSION=5.3.3
RUN set -xe \
    && apk add --no-cache --virtual .build-deps autoconf g++ make pcre-dev re2c \
    && curl -fSL http://pecl.php.net/get/redis-${REDIS_VERSION}.tgz -o redis.tar.gz \
    && mkdir -p /tmp/redis \
    && tar -xf redis.tar.gz -C /tmp/redis --strip-components=1 \
    && rm redis.tar.gz \
    && docker-php-ext-configure /tmp/redis --enable-redis --enable-redis-igbinary \
    && docker-php-ext-install /tmp/redis \
    && rm -r /tmp/redis


RUN php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
   && mv composer.phar /usr/local/bin/composer

# compile a extension
ENV SWOOLE_VERSION=4.6.2
RUN set -xe \
    && curl -fSL http://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz -o swoole.tar.gz \
    && mkdir -p /tmp/swoole \
    && tar -xf swoole.tar.gz -C /tmp/swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && docker-php-ext-configure /tmp/swoole --enable-swoole --enable-openssl \
    && docker-php-ext-install /tmp/swoole \
    && rm -r /tmp/swoole

ENV RABBITMQ_VERSION v0.8.0
RUN git clone --branch ${RABBITMQ_VERSION} https://github.com/alanxz/rabbitmq-c.git /tmp/rabbitmq \
            && cd /tmp/rabbitmq \
            && mkdir build && cd build \
            && cmake .. \
            && cmake --build . --target install \
            && cp -r /usr/local/lib64/* /usr/lib/    

#ENV PHP_AMQP_VERSION 1.10.2
#RUN set -ex \
 #   && curl -fSl http://pecl.php.net/get/amqp-${PHP_AMQP_VERSION}.tgz -o amqp.tar.gz \
#   && mkdir -p /tmp/amqp \
#   && tar -xf amqp.tar.gz -C /tmp/amqp  --strip-components=1 \
#    && rm amqp.tar.gz \
#    && docker-php-ext-configure /tmp/amqp --enable-amqp \
#    && docker-php-ext-install /tmp/amqp \
#    && rm -r /tmp/amqp

RUN set -ex \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/freetype2/freetype \
        --with-jpeg-dir=/usr/include \
        --with-png-dir=/usr/include \
    && docker-php-ext-install soap gd bcmath zip opcache iconv  pdo pcntl sockets shmop xmlrpc \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

ENV APCU_VERSION=5.1.19
# compile apcu extension
RUN set -xe \
    && apk add --no-cache --virtual .build-deps pcre-dev pcre \
    && curl -fsSL http://pecl.php.net/get/apcu-${APCU_VERSION}.tgz -o apcu.tar.gz \
    && mkdir -p /tmp/apcu \
    && tar -xf apcu.tar.gz -C /tmp/apcu --strip-components=1 \
    && rm apcu.tar.gz \
    && docker-php-ext-configure /tmp/apcu --enable-apcu \
    && docker-php-ext-install /tmp/apcu \
    && rm -r /tmp/apcu

RUN rm -rf /tmp/* && rm -rf /var/cache/apk/*
