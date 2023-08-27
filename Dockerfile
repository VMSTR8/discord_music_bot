# Определение базового образа
FROM --platform=$BUILDPLATFORM python:3.10.13-alpine as stage

# Установка рабочей директории внутри контейнера
WORKDIR /discordbot

# Копирование всех файлов из текущей директории (где находится Dockerfile) внутрь контейнера в /discordbot
COPY . .

# Обновление пакетов в Alpine Linux и установка необходимых зависимостей (gcc, musl-dev, python3-dev)
RUN apk update && apk add libffi-dev && apk add gcc musl-dev python3-dev \
    && pip install -U setuptools wheel pip

# Создание колес (wheel) пакетов для зависимостей из requirements.txt и сохранение их в /discordbot/wheels
RUN pip wheel -r requirements.txt --wheel-dir=/discordbot/wheels

# Добавляем исполняемое разрешение к entrypoint.sh
COPY entrypoint.sh /discordbot/entrypoint.sh
RUN chmod +x /discordbot/entrypoint.sh

# Создание нового образа, продолжая с предыдущей секции "stage"
FROM --platform=$BUILDPLATFORM python:3.10.13-alpine

# Копирование файлов из предыдущего образа (stage) в новый образ
COPY --from=stage /discordbot /discordbot

# Установка рабочей директории внутри нового контейнера
WORKDIR /discordbot

# Установка переменной среды для отключения установки бинарных версий pydantic
ENV PIP_NO_BINARY=pydantic

# Установка зависимостей cython и pydantic
RUN pip install cython pydantic && pip install --no-index --find-links=/discordbot/wheels -r requirements.txt

# Установка точки входа для контейнера
ENTRYPOINT ["/discordbot/entrypoint.sh"]
