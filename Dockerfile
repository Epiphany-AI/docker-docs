FROM python:3.13.3-alpine@sha256:452682e4648deafe431ad2f2391d726d7c52f0ff291be8bd4074b10379bb89ff

RUN apk update && apk upgrade --no-cache; \
    apk add --no-cache \
        build-base \
        musl-dev \
        linux-headers \
        libreoffice-writer \
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
        weasyprint \
    ; \
    # More fonts.
    apk add --no-cache --virtual .build-deps \
        msttcorefonts-installer \
    ; \
    # Install microsoft fonts.
    update-ms-fonts; \
    fc-cache -f; \
    # Install Lua packages.
    luarocks-5.4 install lrexlib-pcre; \
    # Clean up when done.
    rm -rf /tmp/*; \
    apk del .build-deps; \
    # Dependencies for Python + PostgreSQL.
    pip install --upgrade pip && \
    apk add --no-cache \
        wget \
        uv \
        libmagic \
        postgresql17-client \
    && rm -rf /var/cache/apk/*
