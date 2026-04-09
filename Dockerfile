FROM steamcmd/steamcmd:ubuntu-24

ENV SERVER_APP_ID=4019830
ENV SERVER_DIR="/opt/dragonwilds"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        lib32stdc++6 \
        lib32gcc-s1 \
        ca-certificates \
        gosu && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash steam && \
    mkdir -p ${SERVER_DIR} && \
    chown -R steam:steam ${SERVER_DIR}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7777/udp

ENTRYPOINT ["/entrypoint.sh"]
