Это проект создавался для рабочих задач. Надеюсь, что он пригодится кому-нибудь ещё, избавив от лишней головной боли.
Буду рад любому отзыву, как положительному, так и отрицательному. Если этот материал тебе хоть как-то помог, не стесняйся, поставь лайк. Спасибо! :)

Проект представляет собой шаблон [Dockerfile](https://docs.docker.com/reference/dockerfile/) для создания контейнеров на базе [Debian](https://www.debian.org/) с использованием веб-сервера [Nginx-Unit](https://unit.nginx.org/) и с вспомогательными инструментами ([xDebug](https://xdebug.org), [composer](https://getcomposer.org)). Дополнительно, в контейнер встроена возможность клонирования репозитория с помощью [GIT](https://git-scm.com/), с возможностью указания вложенной папки.

По умолчанию, при создании контейнера, в директории веб-сервера `/www` создается `index.php`. Он содержит функцию `phpinfo();`. Если после запуска контейнера отображается информация о PHP, это означает, что произошла ошибка при монтировании директории или при клонировании репозитория.

Если вы хотите изменить конфигурацию Nginx-Unit, удалить или добавить дополнительные пакеты, вам необходимо самостоятельно изменить Dockerfile и собрать образ. Список пакетов в репозитории Debian доступен по адресу https://packages.debian.org/en/.

Если дополнительные пакеты не требуются, готовые образы можно скачать с Docker Hub по ссылке https://hub.docker.com/repository/docker/lmrctt/rgisprio/general.
Готовые образы делятся на 2 тега. 
* `lmrctt/rgisprio:dev` - С дополнительными инструментами для разработки и тестирования
* `lmrctt/rgisprio:latest` - Без дополнительных инструментов для разработки и тестирования

### Образ собирается на базе
* debian 12 bookworm

### Используемые пакеты
* php8.2-common
* php8.2-cli
* php8.2-pgsql
* php8.2-zip
* php8.2-gd
* php8.2-uuid
* php8.2-mbstring
* php8.2-xml
* libphp8.2-embed
* php8.2-xdebug
* git
* unit
* unit-php

# Build
### Команда сборки dev образа
```bash
DOCKER_BUILDKIT=1 docker build -f dev.Dockerfile -t rgisprio:dev .
```
### Команда сборки prod образа
```bash
DOCKER_BUILDKIT=1 docker build -f latest.Dockerfile -t rgisprio:latest .
```

# Run
### Клонирование репозитория внутрь контейнера
<p>Для клонирования репозитория внутрь контейнера необходимо указать следующие обязательные переменные</p>

* `GIT_LOGIN` - логин пользователя (Обязательная переменная)
* `GIT_PASSWORD` - пароль пользователя (Обязательная переменная)
* `GIT_URL` - ссылка на репозиторий "https://github.com/another-ghu/docker.git" (Обязательная переменная)

<p>Опциональная переменная необходима в том случае, если кодовая база находится во вложенной папке</p>

* `GIT_DIR` - папка с кодом если находится во вложенной папке (Опциональная переменная)

### Базовая команда запуска
```bash
export RGISPRIO=$(docker run -p 81:80 \
--rm                                  \
--name rgisprio.dev                   \
lmrctt/rgisprio:dev)
```

### Команда запуска контейнера с примонтированной папкой
```bash
export RGISPRIO=$(docker run                 \
-p 81:80                                     \
--mount type=bind,src="$(pwd)",dst=/www      \
--add-host host.docker.internal:host-gateway \
--rm                                         \
--name rgisprio.dev                          \
lmrctt/rgisprio:dev)
```
### Описание ключей
* `-p 81:80` - Прокидывает порт в контейнер.
* `--mount type=bind,src="$(pwd)",dst=/www` - монтирование текущей директории из которой производится запуск
* `--add-host host.docker.internal:host-gateway` - добавления пользовательского хоста в файл /etc/hosts контейнера. Это позволяет контейнеру видеть и использовать этот хост как локальный. Необходимо для корректной работы xDebug.
* `--rm` - удаляет контейнер после остановки.
* `--name` rgisprio.dev - имя контейнера.

### Команда запуска контейнера с клонированием репозитория и указанием папки с кодом 
```bash
export RGISPRIO=$(docker run -p 81:80                   \
--env GIT_LOGIN=dev                                     \
--env GIT_PASSWORD=changeme                             \
--env GIT_URL=https://github.com/another-ghu/docker.git \
--env GIT_DIR=/app/                                     \
--add-host host.docker.internal:host-gateway            \
--rm                                                    \
--name rgisprio.dev                                     \
lmrctt/rgisprio:dev)
```

### Описание ключей
* `-p 81:80` - Прокидывает порт в контейнер.
* `--env GIT_LOGIN=dev` - имя пользователя git.
* `--env GIT_URL=https://github.com/another-ghu/docker.git` - адрес репозитория.
* `--env GIT_DIR=/app/` - директория с кодом.
* `--add-host host.docker.internal:host-gateway` - добавления пользовательского хоста в файл /etc/hosts контейнера. Это позволяет контейнеру видеть и использовать этот хост как локальный. Необходимо для корректной работы xDebug.
* `--rm` - удаляет контейнер после остановки.
* `--name` rgisprio.dev - имя контейнера.
* `lmrctt/rgisprio:dev` - имя образа для запуска контейнера.



