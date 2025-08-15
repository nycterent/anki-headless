# Multi-stage build for Anki headless with AnkiConnect
FROM ubuntu:22.04 AS builder

ARG ANKI_VERSION=25.07.5
ARG ANKICONNECT_VERSION=23.10.29.0
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies for downloading and extracting
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and prepare Anki
WORKDIR /tmp
RUN wget -O anki.tar.xz "https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-qt6.tar.xz" \
    && tar -xf anki.tar.xz

# Download AnkiConnect plugin
RUN wget -O ankiconnect.zip "https://github.com/FooSoft/anki-connect/releases/download/${ANKICONNECT_VERSION}/anki-connect.zip" \
    && unzip ankiconnect.zip -d ankiconnect

# Final stage
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG ANKI_VERSION=25.07.5

# Create anki user
RUN groupadd -r anki && useradd -r -g anki -m -d /home/anki anki

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libxcb-xinerama0 \
    libxcb-cursor0 \
    libnss3 \
    libxss1 \
    libgconf-2-4 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    gconf-service \
    libappindicator1 \
    libc6 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgcc1 \
    libglib2.0-0 \
    libnspr4 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libdrm2 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxshmfence1 \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    xvfb \
    curl \
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Copy Anki from builder stage
COPY --from=builder /tmp/anki-${ANKI_VERSION}-linux-qt6 /opt/anki

# Create symlink for anki command
RUN ln -sf /opt/anki/bin/anki /usr/local/bin/anki

# Set up Anki directories
USER anki
WORKDIR /home/anki

# Create Anki profile directories
RUN mkdir -p /home/anki/.local/share/Anki2/User\ 1/addons21/2055492159 \
    && mkdir -p /home/anki/.local/share/Anki2/User\ 1/collection.media

# Copy AnkiConnect addon
COPY --from=builder --chown=anki:anki /tmp/ankiconnect/plugin/* /home/anki/.local/share/Anki2/User\ 1/addons21/2055492159/

# Copy configuration and startup files
COPY --chown=anki:anki config.json /home/anki/.local/share/Anki2/User\ 1/addons21/2055492159/config.json
COPY --chown=anki:anki meta.json /home/anki/.local/share/Anki2/User\ 1/addons21/2055492159/meta.json
COPY --chown=anki:anki start-anki.sh /home/anki/start-anki.sh

# Make startup script executable
RUN chmod +x /home/anki/start-anki.sh

# Environment variables
ENV ANKI_DATA_DIR=/home/anki/.local/share/Anki2
ENV ANKI_PORT=8765
ENV ANKI_CORS_ORIGINS="*"
ENV DISPLAY=:99

# Expose AnkiConnect port
EXPOSE 8765

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8765 || exit 1

# Start Anki in headless mode
CMD ["/home/anki/start-anki.sh"]