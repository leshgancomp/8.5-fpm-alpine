FROM php:8.5-fpm-alpine

ARG TZ=UTC
ARG UID=1000
ARG GID=1000

ENV TZ=${TZ}
ENV UID=${UID}
ENV GID=${GID}

# Add a non-root user
RUN addgroup -g $GID symfony && \
    adduser -u $UID -G symfony -s /bin/sh -D symfony

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install PHP extension installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install system dependencies, PHP extensions, and clean up in a single layer
RUN apk add --no-cache \
        mariadb-client \
        ca-certificates \
        postgresql-client \
        libssh2 \
        zip \
        libzip \
        libxml2 \
        jpegoptim \
        optipng \
        pngquant \
        gifsicle \
        libxslt \
        rabbitmq-c \
        icu-libs \
        oniguruma \
        gmp \
        freetype \
        libjpeg-turbo \
        libpng \
        jpeg \
        libwebp \
        supervisor \
        bash \
        curl \
        unzip \
        git \
        fcgi \
        nodejs \
        npm \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        postgresql-dev \
        libssh-dev \
        libzip-dev \
        libxml2-dev \
        libxslt-dev \
        rabbitmq-c-dev \
        icu-dev \
        oniguruma-dev \
        gmp-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        jpeg-dev \
        libwebp-dev \
        linux-headers
RUN chmod +x /usr/local/bin/install-php-extensions &&  \
    install-php-extensions bcmath exif gd gmp intl mysqli pcntl pdo_mysql pdo_pgsql sockets xsl zip redis amqp &&  \
    install-php-extensions xdebug && \
    apk del .build-deps && \
    rm -rf /var/cache/apk/*

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

COPY --link docker/php/10-app.ini $PHP_INI_DIR/conf.d/
COPY --link docker/php/20-app.dev.ini $PHP_INI_DIR/conf.d/

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Switch to non-root user
USER symfony

WORKDIR /app

# Expose port 9000 and start php-fpm server
EXPOSE 9000

#HEALTHCHECK --interval=5m --timeout=3s \
#  CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -connect 127.0.0.1:9000 || exit 1

CMD ["php-fpm"]
