FROM python:3.14-alpine@sha256:8373231e1e906ddfb457748bfc032c4c06ada8c759b7b62d9c73ec2a3c56e710

RUN <<EOF
    apk update && apk upgrade --no-cache
    apk add --no-cache \
        build-base \
        musl-dev \
        linux-headers \
        openjdk21-jre-headless \
        libreoffice-common \
        libreoffice-writer \
        libreoffice-impress \
        pandoc-cli \
        fontconfig \
        freetype \
        libc-dev \
        lua5.4-dev \
        luarocks \
        pcre-dev \
        ttf-dejavu \
        ttf-droid \
        ttf-freefont \
        ttf-liberation \
        weasyprint

    # More fonts
    apk add --no-cache --virtual .build-deps \
        msttcorefonts-installer

    # Install microsoft fonts
    update-ms-fonts
    fc-cache -f

    # Install Lua packages
    luarocks-5.4 install lrexlib-pcre

    # Clean up when done
    rm -rf /tmp/*
    apk del .build-deps

    # Dependencies for Python + PostgreSQL
    pip install --upgrade pip
    pip install --upgrade pillow
    apk add --no-cache \
        wget \
        uv \
        libmagic \
        postgresql17-client
    rm -rf /var/cache/apk/*
EOF
