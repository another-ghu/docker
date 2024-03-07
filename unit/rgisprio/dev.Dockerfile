#Минимальный образ nginx unit без установленных языковых модулей
FROM debian:bookworm
#debian 12 bookworm

LABEL org.opencontainers.image.authors="another.mfj@yandex.ru"
LABEL org.opencontainers.image.title="Rgisprio"
LABEL org.opencontainers.image.description="Image for development"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/lmrctt/rgisprio"
LABEL org.opencontainers.image.source="https://github.com/another-ghu/docker/tree/main/unit/rgisprio"
LABEL org.opencontainers.image.documentation="https://github.com/another-ghu/docker/tree/main/unit/rgisprio"
LABEL org.opencontainers.image.version="dev"

RUN <<Packages
#
#Обновляем списки репозиториев. Устанавливаем необходимые стартовые пакеты
  apt update  && apt -y install \
    curl apt-transport-https gnupg2 lsb-release

#Добавляем репозитории nginx unit
  curl -o /usr/share/keyrings/nginx-keyring.gpg https://unit.nginx.org/keys/nginx-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg]       \
    https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit" \
    >> /etc/apt/sources.list.d/unit.list
  echo "deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg]   \
    https://packages.nginx.org/unit/debian/ `lsb_release -cs` unit" \
    >> /etc/apt/sources.list.d/unit.list

# Устанавливаем необходимые пакеты
  apt update  && apt -y install         \
    php8.2-common                       \
    php8.2-cli                          \
    php8.2-pgsql                        \
    php8.2-zip                          \
    php8.2-gd                           \
    php8.2-uuid                         \
    php8.2-mbstring                     \
    php8.2-xml                          \
    libphp8.2-embed                     \
    php8.2-xdebug                       \
    git                                 \
    unit                                \
    unit-php

# Удаляем ненужные пакеты
  apt remove apt-transport-https gnupg2 lsb-release && apt autoremove --purge -y
# Удаляем ненужные пакеты c конфигурациями и удаляем списки репозиториев.
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list
Packages

#Добавляем необходимые локальные файлы во временную директорию контейнера
COPY /unit/rgisprio/dev.docker-entrypoint.sh /tmp

RUN <<Configurations
#

# Создаем папку /docker-entrypoint.d и добавляем конфигурацию nginx unit unit.json
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

# Создаем папку /www и добавляем стартовый index.php
mkdir /www/
cat << 'Index' > /www/index.php
<?php phpinfo();' >

Index

# Добавляем конфигурацию xDebug
cat << 'xDebug' > /etc/php/8.2/embed/conf.d/99-xdebug.ini
xdebug.mode=develop, debug
xdebug.start_with_request=yes
xdebug.discover_client_host=0
xdebug.client_host=host.docker.internal
xDebug

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
