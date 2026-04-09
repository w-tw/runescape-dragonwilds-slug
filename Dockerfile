FROM steamcmd/steamcmd:ubuntu-24

ARG SERVER_APP_ID=4019830
ENV SERVER_APP_ID=${SERVER_APP_ID}
ENV SERVER_DIR="/opt/dragonwilds"
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        lib32stdc++6 \
        lib32gcc-s1 \
        ca-certificates \
        gettext-base && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${SERVER_DIR}

RUN steamcmd \
    +force_install_dir ${SERVER_DIR} \
    +login anonymous \
    +app_update ${SERVER_APP_ID} validate \
    +quit

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7777/udp

ENTRYPOINT ["/entrypoint.sh"]
