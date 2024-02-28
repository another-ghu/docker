#Минимальный образ nginx unit без установленных языковых модулей
FROM unit:1.31.1-minimal
#debian 11 bullseye

LABEL org.opencontainers.image.authors="another.mfj@yandex.ru"
LABEL org.opencontainers.image.title="Rgisprio"
LABEL org.opencontainers.image.description="Image for production"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/lmrctt/rgisprio"
LABEL org.opencontainers.image.source="https://github.com/another-ghu/docker/tree/main/unit/rgisprio"
LABEL org.opencontainers.image.documentation="https://github.com/another-ghu/docker/tree/main/unit/rgisprio"
LABEL org.opencontainers.image.version="latest"

RUN <<Packages
#
  apt update
  # Устанавливаем необходимые стартовые пакеты
  apt install -y curl apt-transport-https gnupg2 lsb-release
  #Добавляем репозитории nginx unit
  curl -o /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg]       \
    https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit" \
    >> /etc/apt/sources.list.d/unit.list
  echo "deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg]   \
    https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit" \
    >> /etc/apt/sources.list.d/unit.list
  # Обновляем списки репозиториев
  apt update
  # Устанавливаем необходимые пакеты
  apt install -y                        \
    php7.4-common                       \
    php7.4-cli                          \
    php7.4-pgsql                        \
    php7.4-zip                          \
    php7.4-gd                           \
    php7.4-uuid                         \
    php7.4-mbstring                     \
    libphp7.4-embed                     \
    php7.4-dev                          \
    unit                                \
    unit-php
  pecl channel-update pecl.php.net
  pecl install xdebug-3.1.0

  # Удаляем ненужные пакеты
  apt remove apt-transport-https gnupg2 lsb-release php7.4-dev
  # Удаляем ненужные пакеты c конфигурациями и удаляем списки репозиториев.
  apt autoremove --purge -y
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list
Packages

RUN <<Configurations
#
mkdir /www/
echo '<?php phpinfo();' > /www/index.php
chmod -R 775 /www
# Unit configuration
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
                "pass": "applications/rgisprio"

            },
        },
    ],
    "applications": {
        "rgisprio": {
            "type": "php",
            "root": "/www/",
            "index": "index.php",
            "user": "www-data",
            "group": "www-data"
        }
    }
}
Unit
#Xdebug configuration
echo "zend_extension = xdebug" >> /etc/php/7.4/embed/php.ini
cat << 'xdebug' > /etc/php/7.4/embed/conf.d/99-xdebug.ini
xdebug.mode=develop, debug
xdebug.start_with_request=yes
xdebug.discover_client_host=0
xdebug.client_host=host.docker.internal
xdebug

Configurations

EXPOSE 80
# normal
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
# debug
#CMD ["unitd-debug","--no-daemon","--control","unix:/var/run/control.unit.sock"]