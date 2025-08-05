FROM php:8.3-fpm-alpine

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    nodejs \
    npm \
    oniguruma-dev \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    mysql-client \
    supervisor

# Install PHP extensions for production
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install \
    bcmath \
    exif \
    gd \
    mysqli \
    opcache \
    pdo_mysql \
    pcntl \
    zip \
    intl \
    soap

# Install Redis extension
RUN apk add --no-cache pcre-dev $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev $PHPIZE_DEPS

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN addgroup -g 1000 www
RUN adduser -G www -g www -s /bin/sh -D www

# Copy application files
COPY --chown=www:www . /var/www

# Install PHP dependencies for production
USER www
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Install Node.js dependencies and build assets for production
RUN npm ci --only=production
RUN npm run build

# Clean up development files
RUN rm -rf node_modules

# Switch back to root for final setup
USER root

# Set proper permissions
RUN chown -R www:www /var/www/storage /var/www/bootstrap/cache

# Production PHP configuration
COPY <<EOF /usr/local/etc/php/conf.d/production.ini
# Production PHP settings
memory_limit=256M
max_execution_time=60
upload_max_filesize=20M
post_max_size=25M

# OPcache settings for production
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=0
opcache.validate_timestamps=0
opcache.save_comments=1
opcache.fast_shutdown=1
EOF

# Change current user to www
USER www

# Expose port 9000 for php-fpm
EXPOSE 9000

CMD ["php-fpm"] 