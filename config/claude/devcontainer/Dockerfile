FROM ghcr.io/anthropics/claude-code:latest

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*
