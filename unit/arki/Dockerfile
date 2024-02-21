#Минимальный образ nginx unit без установленных языковых модулей
FROM unit:1.31.1-minimal
#debian 10 buster

LABEL authors="another.mfj@yandex.ru"

# Подключаем необходимые репозитории
RUN apt update && apt install -y curl apt-transport-https gnupg2 lsb-release                      \
    && curl -o /usr/share/keyrings/nginx-keyring.gpg                                              \
           https://unit.nginx.org/keys/nginx-keyring.gpg                                          \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg]                                \
             https://packages.nginx.org/unit/debian/ buster unit"                                 \
           >> /etc/apt/sources.list.d/unit.list                                                   \
    && echo "deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg]                            \
             https://packages.nginx.org/unit/debian/ buster unit"                                 \
           >> /etc/apt/sources.list.d/unit.list                                                   \
    && echo "deb http://deb.debian.org/debian/ buster main"                                       \
           >> /etc/apt/sources.list                                                               \
    && echo "deb http://security.debian.org/debian-security buster/updates main"                  \
           >> /etc/apt/sources.list

# Устанавливаем необходимые пакеты.
RUN apt update && apt install -y \
    php7.3-common/oldoldstable   \
    php7.3-cli/oldoldstable      \
    php7.3-bcmath/oldoldstable   \
    php7.3-curl/oldoldstable     \
    php7.3-xml/oldoldstable      \
    php7.3-gd/oldoldstable       \
    php7.3-mbstring/oldoldstable \
    php7.3-pgsql/oldoldstable    \
    php7.3-xml/oldoldstable      \
    php7.3-zip/oldoldstable      \
    libphp-embed/oldoldstable    \
    php-amqp=1.9.4-1             \
    php7.3-dev                   \
    unit                         \
    unit-php

# 1. Устанавливаем pecl.
# 2. Конфигурируем xdebug
# 3. Конфигурируем nginx unit
# Требуемые пакеты
# php7.3-dev
RUN pecl install xdebug-3.1.0                                                                    \
    && echo "zend_extension = xdebug" >> /etc/php/7.3/embed/php.ini                              \
    && echo "xdebug.mode=develop, debug" > /etc/php/7.3/embed/conf.d/99-xdebug.ini               \
    && echo 'xdebug.start_with_request=yes' >> /etc/php/7.3/embed/conf.d/99-xdebug.ini           \
    && echo 'xdebug.discover_client_host=0' >> /etc/php/7.3/embed/conf.d/99-xdebug.ini           \
    && echo 'xdebug.client_host=host.docker.internal' >> /etc/php/7.3/embed/conf.d/99-xdebug.ini \
    && mkdir /www/                                                                               \
    && echo '{                                                                                   \
    "listeners": {                                                                               \
        "*:80": {                                                                                \
            "pass": "applications/php_app"                                                       \
        }                                                                                        \
    },                                                                                           \
    "applications": {                                                                            \
        "php_app": {                                                                             \
            "type": "php",                                                                       \
            "root": "/www/"                                                                      \
        }                                                                                        \
    }                                                                                            \
    }' > /docker-entrypoint.d/config.json

# Удаляем ненужные пакеты и очищаем списки репозиториев.
RUN apt remove -y apt-transport-https gnupg2 lsb-release php7.3-dev \
    && apt autoremove --purge -y                                    \
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list