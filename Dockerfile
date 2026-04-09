FROM steamcmd/steamcmd:ubuntu-24

ENV SERVER_APP_ID=4019830
ENV SERVER_DIR="/opt/dragonwilds"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        lib32stdc++6 \
        lib32gcc-s1 \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${SERVER_DIR}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7777/udp

ENTRYPOINT ["/entrypoint.sh"]
