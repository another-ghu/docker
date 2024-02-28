#Минимальный образ nginx unit без установленных языковых модулей
FROM debian:bookworm
#debian 12 bookworm

LABEL org.opencontainers.image.authors="another.mfj@yandex.ru"
LABEL org.opencontainers.image.title="MKD"
LABEL org.opencontainers.image.description="Image for development"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/lmrctt/mkd"
LABEL org.opencontainers.image.source="https://github.com/another-ghu/docker/tree/main/unit/mkd"
LABEL org.opencontainers.image.documentation="https://github.com/another-ghu/docker/tree/main/unit/mkd"
LABEL org.opencontainers.image.version="dev"

#Добавляем composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

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
  apt update  && apt -y install \
    php8.2-common                       \
    php8.2-cli                          \
    php8.2-pgsql                        \
    php8.2-zip                          \
    php8.2-gd                           \
    php8.2-uuid                         \
    php8.2-mbstring                     \
    libphp8.2-embed                     \
    php8.2-curl                         \
    php8.2-xml                          \
    php8.2-xdebug                       \
    unit                                \
    unit-php

# Удаляем ненужные пакеты
  apt remove apt-transport-https gnupg2 lsb-release && apt autoremove --purge -y
# Удаляем ненужные пакеты c конфигурациями и удаляем списки репозиториев.
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list
Packages

RUN <<Configurations
#
# Скачиваем docker-entrypoint.sh и устанавливаем права на его исполнение
# https://github.com/nginx/unit/tree/master/pkg/docker
curl -o /usr/local/bin/docker-entrypoint.sh                                           \
  https://raw.githubusercontent.com/nginx/unit/master/pkg/docker/docker-entrypoint.sh \
  && chmod ugo+x /usr/local/bin/docker-entrypoint.sh

# Создаем папку /docker-entrypoint.d и добавляем конфигурацию nginx unit unit.json
mkdir /docker-entrypoint.d/
cat << 'Unit' > /docker-entrypoint.d/unit.json
{
    "listeners":{
        "*:80":{
            "pass": "routes"
        }
    },
    "routes":[
        {
            "match":{
                "uri":[
                    "*.php",
                    "*.php/*"
                ]
            },
            "action":{
                "pass": "applications/mkd/direct"
            }
        },
        {
            "action":{
                "share": "public$uri",
                "fallback":{
                    "pass": "applications/mkd/index"
                }
            }
        }
    ],
    "applications":{
        "mkd":{
            "type": "php",
            "targets":{
                "direct":{
                    "root": "/www/public/"
                },
                "index":{
                    "root": "/www/public/",
                    "script": "index.php"
                }
            }
        }
    }
}
Unit

# Создаем папку /www и добавляем стартовый index.php
mkdir /www/
cat << 'Index' > /www/index.php
<?php phpinfo();' >

Index

cat << 'xDebug' > /etc/php/8.2/embed/conf.d/99-xdebug.ini
xdebug.mode=develop, debug
xdebug.start_with_request=yes
xdebug.discover_client_host=0
xdebug.client_host=host.docker.internal
xDebug
#Перенаправляем вывод ошибок.
ln -sf /dev/stderr /var/log/unit.log
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