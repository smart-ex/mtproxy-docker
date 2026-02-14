# MTProxy - Multi-stage build from official Telegram MTProxy source
# https://github.com/TelegramMessenger/MTProxy

# Stage 1: Build
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --depth 1 https://github.com/TelegramMessenger/MTProxy . \
    && make

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    iproute2 \
    libssl3 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy
COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]
