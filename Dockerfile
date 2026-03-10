# Production-ready Dockerfile for OpenCATS
# Optimized for Railway deployment

FROM php:8.0-apache

# Set metadata for Railway
LABEL org.opencontainers.image.title="OpenCATS"
LABEL org.opencontainers.image.description="OpenCATS Applicant Tracking System"
LABEL org.opencontainers.image.version="1.0.0"

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libxml2-dev \
    default-mysql-client \
    zip \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    mysqli \
    gd \
    mbstring \
    curl \
    xml \
    zip

# Enable Apache modules and fix MPM conflict
RUN a2enmod rewrite headers \
    && a2dismod mpm_event 2>/dev/null || true

# Configure Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configure PHP settings
RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize = 20M" > /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size = 20M" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/execution-time.ini

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . /var/www/html/

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/temp /var/www/html/upload /var/www/html/attachments \
    && chown -R www-data:www-data /var/www/html/temp \
    && chown -R www-data:www-data /var/www/html/upload \
    && chown -R www-data:www-data /var/www/html/attachments \
    && chmod -R 755 /var/www/html/temp \
    && chmod -R 755 /var/www/html/upload \
    && chmod -R 755 /var/www/html/attachments

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy Apache virtual host configuration
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy start script
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

# Expose port 80 for HTTP
EXPOSE 80

# Use start script which starts Apache immediately and runs database setup in background
CMD ["/usr/local/bin/start.sh"]
