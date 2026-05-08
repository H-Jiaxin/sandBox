FROM debian:stable-slim
RUN apt update && apt install -y --no-install-recommends \
    git curl wget procps ca-certificates vim htop && \
    rm -rf /var/lib/apt/lists/*
