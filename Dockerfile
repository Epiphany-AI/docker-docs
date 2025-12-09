FROM python:3.13.10-alpine@sha256:65fe04ddc51a8ccbf14ecb882903251e4a124914673001b03c393eb65dd9502a

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
