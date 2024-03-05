#Минимальный образ nginx unit без установленных языковых модулей
FROM debian:bookworm
#debian 12 bookworm

LABEL org.opencontainers.image.authors="another.mfj@yandex.ru"
LABEL org.opencontainers.image.title="mkd-react"
LABEL org.opencontainers.image.description="Image for development"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/lmrctt/mkd-react"
LABEL org.opencontainers.image.source="https://github.com/another-ghu/docker/tree/main/unit/mkd-react"
LABEL org.opencontainers.image.documentation="https://github.com/another-ghu/docker/tree/main/unit/mkd-react"
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
  apt update  && apt -y install \
    npm                         \
    unit                        \
    unit-dev

  npm install -g --unsafe-perm unit-http

# Удаляем ненужные пакеты
  apt remove apt-transport-https gnupg2 lsb-release && apt autoremove --purge -y
# Удаляем ненужные пакеты c конфигурациями и удаляем списки репозиториев.
  rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list
Packages

#Добавляем необходимые локальные файлы во временную директорию контейнера
COPY /unit/mkd-react/dev.docker-entrypoint.sh /tmp

RUN <<Configurations
#

mkdir /docker-entrypoint.d/
cat << 'Unit' > /docker-entrypoint.d/unit.json
{
    "listeners": {
        "*:80": {
            "pass": "applications/apollo"
        }
    },

    "applications": {
        "apollo": {
            "type": "external",
            "working_directory": "/www",
            "executable": "/usr/bin/env",
            "arguments": [
                "node",
                "--loader",
                "unit-http/loader.mjs",
                "--require",
                "unit-http/loader",
                "app.js"
            ]
        }
    }
}
Unit

mv /tmp/dev.docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
chmod ugo+x /usr/local/bin/docker-entrypoint.sh

#Перенаправляем вывод ошибок.
#ln -sf /dev/stderr /var/log/unit.log
Configurations
#COPY /unit/mkd-react/package.json /tmp

STOPSIGNAL SIGTERM

# Пробрасываем порт в контейнер
EXPOSE 80
# Запускаем docker-entrypoint.sh при старте контейнера
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Запускаем nginx unit в нормальном режиме
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
# Запускаем nginx unit в debug режиме
#CMD ["unitd-debug","--no-daemon","--control","unix:/var/run/control.unit.sock"]
