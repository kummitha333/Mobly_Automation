# Base image
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    adb \
    net-tools \
    iproute2 \
    sudo \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Mobly
RUN pip3 install mobly

# Create non-root user
RUN useradd -m appuser && echo 'appuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set up PATH and local bin
RUN mkdir -p /home/appuser/.local/bin
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Set working directory and copy files as root
WORKDIR /app
COPY mobly-bundled-snippets.apk /app/mobly-bundled-snippets.apk
COPY tools/snippet_shell.py /app/snippet_shell.py
COPY start_snippet.sh /app/start_snippet.sh

# ✅ CHMOD must happen before switching to appuser
RUN chmod +x /app/start_snippet.sh

# Now switch to appuser
USER appuser

# Download and install gotty as root, then move it to a location accessible by appuser
USER root
WORKDIR /home/appuser
RUN wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz \
    && tar xvzf gotty_linux_amd64.tar.gz \
    && mv gotty /home/appuser/.local/bin/gotty \
    && chown appuser:appuser /home/appuser/.local/bin/gotty

# App directory for execution
WORKDIR /app

# Expose gotty terminal port
EXPOSE 8085

# Start Mobly snippet shell via gotty
CMD [ "gotty", "-w", "-p", "8085", "/app/start_snippet.sh" ]

