# hadolint global ignore=DL3013,DL3018,DL3042

FROM python:3.13.13-alpine@sha256:70dd89363f8665af9a8076ef505bfd8b8bf2fb0b3ab45860cd3494ab7197fe73

# Only update package listing
RUN apk update

# System package index update and base build dependencies
RUN <<EOF
    apk add --no-cache \
        build-base \
        musl-dev \
        linux-headers \
        libc-dev \
        pcre-dev \
        cargo
    rm -rf /var/cache/apk/*
EOF

# Ghostscript
RUN <<EOF
    apk add --no-cache \
        ghostscript
    rm -rf /var/cache/apk/*
EOF

# LibreOffice and Java runtime
RUN <<EOF
    apk add --no-cache \
        openjdk21-jre-headless \
        libreoffice-common \
        libreoffice-writer \
        libreoffice-impress \
        pandoc-cli
    rm -rf /var/cache/apk/*
EOF

# Font configuration and system fonts
RUN <<EOF
    apk add --no-cache \
        fontconfig \
        freetype \
        ttf-dejavu \
        ttf-droid \
        ttf-freefont \
        ttf-liberation
    rm -rf /var/cache/apk/*
EOF

# Microsoft fonts (requires build dependencies temporarily)
RUN <<EOF
    apk add --no-cache --virtual .build-deps \
        msttcorefonts-installer
    update-ms-fonts
    fc-cache -f
    apk del .build-deps
    rm -rf /var/cache/apk/* /tmp/*
EOF

# Lua runtime and packages
RUN <<EOF
    apk add --no-cache \
        lua5.4-dev \
        luarocks
    luarocks-5.4 install lrexlib-pcre
    rm -rf /var/cache/apk/*
EOF

# System utilities and database clients (PostgreSQL, Redis CLI)
RUN <<EOF
    apk add --no-cache \
        wget \
        uv \
        libmagic \
        redis \
        postgresql17-client
    rm -rf /var/cache/apk/*
EOF

# Python dependencies
RUN <<EOF
    pip install --upgrade pip
    pip install --upgrade "pillow>=12.1.0"
    pip install --upgrade "weasyprint>=68"
    rm -rf /tmp/* /root/.cache/pip/*
EOF

# Final system upgrade for security patches (keeps earlier layers stable)
RUN <<EOF
    apk upgrade --no-cache
    rm -rf /var/cache/apk/*
EOF
