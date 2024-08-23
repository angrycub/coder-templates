ARG ARCH=
FROM ${ARCH}library/clojure:latest

RUN apt update && \
    apt install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd coder \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group && \
    mkdir -p /etc/sudoers.d && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers.d/nopasswd

USER coder

