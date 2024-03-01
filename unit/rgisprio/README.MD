
Для клонирования репозитория git в контейнер необходимо указать 3 обязательные переменные.
Обязательные переменные.
GIT_LOGIN
GIT_PASSWORD
GIT_URL

Опциональные переменные.
GIT_DIR

Пример запуска контейнера

docker run -p 81:80                                     \
--env GIT_DIR=/app/                                     \
--env GIT_LOGIN=dev                                     \
--env GIT_PASSWORD=changeme                             \
--env GIT_URL=https://github.com/another-ghu/docker.git \
--name rgisprio.dev                                     \
--add-host host.docker.internal:host-gateway            \
--rm                                                    \
lmrctt/rgisprio:dev

