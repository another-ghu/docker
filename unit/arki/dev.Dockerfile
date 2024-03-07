#Минимальный образ nginx unit без установленных языковых модулей
FROM debian:buster
#debian 10 buster

LABEL org.opencontainers.image.authors="another.mfj@yandex.ru"
LABEL org.opencontainers.image.title="Arki"
LABEL org.opencontainers.image.description="Image for development"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/lmrctt/arki"
LABEL org.opencontainers.image.source="https://github.com/another-ghu/docker/tree/main/unit/arki"
LABEL org.opencontainers.image.documentation="https://github.com/another-ghu/docker/tree/main/unit/arki"
LABEL org.opencontainers.image.version="dev"

RUN <<Packages
# add repositories and install pkg
apt update && apt install -y curl apt-transport-https gnupg2 lsb-release                          \
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

apt update && apt install -y     \
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

pecl install xdebug-3.1.0

apt remove -y         \
  apt-transport-https \
  gnupg2              \
  lsb-release         \
  php7.3-dev

apt autoremove --purge -y

rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list
Packages

COPY /unit/arki/dev.docker-entrypoint.sh /tmp

RUN <<Configurations
# creating configuration files
mkdir /docker-entrypoint.d/
cat << 'Unit' > /docker-entrypoint.d/unit.json
{
    "listeners":
    {
        "*:80":
        {
            "pass": "routes"
        },
        "*:443":
        {
            "pass": "routes"
        },
    },

    "routes":
    [
        {
            "match":
            {
                "uri": "~\\.(css|gif|ico|jpg|js(on)?|png|svg|ttf|woff2?)$"
            },
            "action":
            {
                "share": "/www$uri"
            },
        },
        {
            "action":
            {
                "pass": "applications/arki"

            },
        },
    ],
    "applications": {
        "arki": {
            "type": "php",
            "root": "/www/",
            "index": "index.php",
            "user": "www-data",
            "group": "www-data"
        }
    }
}
Unit

# Создаем папку /www и добавляем стартовый index.php
mkdir /www/
cat << 'index.php' > /www/index.php
<?php phpinfo();

index.php

# Добавляем конфигурацию xDebug
cat << '99-xdebug.ini' > /etc/php/7.3/embed/conf.d/99-xdebug.ini
xdebug.mode=develop, debug
xdebug.start_with_request=yes
xdebug.discover_client_host=0
xdebug.client_host=host.docker.internal
99-xdebug.ini

# Активируем расширение xdebug в php.ini
echo "zend_extension = xdebug" >> /etc/php/7.3/embed/php.ini

# php.ini Включение легаси поддержки для коротких тегов <?
sed -i '/short_open_tag = Off/c short_open_tag = On' /etc/php/7.3/embed/php.ini

mv /tmp/dev.docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
chmod ugo+x /usr/local/bin/docker-entrypoint.sh

#Перенаправляем вывод ошибок.
#ln -sf /dev/stderr /var/log/unit.log
Configurations

STOPSIGNAL SIGTERM

# Пробрасываем порт в контейнер
EXPOSE 80
# Запускаем docker-entrypoint.sh при старте контейнера
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Запускаем nginx unit в нормальном режиме
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
# Запускаем nginx unit в debug режиме
#CMD ["unitd-debug","--no-daemon","--control","unix:/var/run/control.unit.sock"]
