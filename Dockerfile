# =========================
# 1. BUILD FRONTEND (VITE)
# =========================
FROM node:20-alpine AS node_builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build


# =========================
# 2. APP (PHP + NGINX + SUPERVISOR)
# =========================
FROM php:8.2-fpm-alpine

# Instalar paquetes
RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    oniguruma-dev \
    zip \
    unzip

# Extensiones PHP
RUN docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copiar proyecto
COPY . .

# Instalar dependencias Laravel
RUN composer install --no-dev --optimize-autoloader

# Copiar build frontend
COPY --from=node_builder /app/public/build ./public/build

# Permisos
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Configs
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisord.conf

# Exponer puerto
EXPOSE 80

# Comando principal
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]