FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV SERVER_DIR="/opt/dragonwilds"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        unzip \
        procps \
        libicu-dev \
        gettext-base \
        gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# .NET 8 runtime (required by DepotDownloader)
RUN curl -sL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 8.0 --runtime dotnet --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    rm /tmp/dotnet-install.sh

# DepotDownloader — anonymous Steam content downloader (no login required)
ARG DEPOT_DOWNLOADER_VERSION=3.4.0
RUN curl -sL "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/DepotDownloader-linux-x64.zip" -o /tmp/dd.zip && \
    mkdir -p /depotdownloader && \
    unzip /tmp/dd.zip -d /depotdownloader && \
    chmod +x /depotdownloader/DepotDownloader && \
    rm /tmp/dd.zip

RUN useradd -m -s /bin/bash steam && \
    mkdir -p ${SERVER_DIR} && \
    chown -R steam:steam ${SERVER_DIR}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7777/udp

HEALTHCHECK --start-period=5m \
    CMD pgrep -f "RSDragonwilds" > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
