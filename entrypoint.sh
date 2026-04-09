#!/bin/bash
set -e

CONFIG_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer"
CONFIG_FILE="${CONFIG_DIR}/DedicatedServer.ini"
SAVEGAMES_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Savegames"
LOGS_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Logs"

# --- Validate Steam credentials ---
if [ -z "${STEAM_USER}" ]; then
    echo "[entrypoint] ERROR: STEAM_USER is required (this app does not support anonymous download)."
    exit 1
fi

STEAM_LOGIN="+login ${STEAM_USER}"
if [ -n "${STEAM_PASS}" ]; then
    STEAM_LOGIN="+login ${STEAM_USER} ${STEAM_PASS}"
fi

# --- Install / update server ---
if [ "${UPDATE_ON_START}" != "false" ]; then
    echo "[entrypoint] Installing/updating dedicated server (app ${SERVER_APP_ID})..."
    steamcmd \
        +force_install_dir "${SERVER_DIR}" \
        ${STEAM_LOGIN} \
        +app_update "${SERVER_APP_ID}" validate \
        +quit
    echo "[entrypoint] Update complete."
fi

# --- Create directories ---
mkdir -p "${CONFIG_DIR}" "${SAVEGAMES_DIR}" "${LOGS_DIR}"

# --- Generate DedicatedServer.ini from environment variables ---
if [ -z "${OWNER_ID}" ]; then
    echo "[entrypoint] ERROR: OWNER_ID is required. Find it in-game at Settings > bottom of menu."
    exit 1
fi

if [ -z "${SERVER_NAME}" ]; then
    echo "[entrypoint] ERROR: SERVER_NAME is required."
    exit 1
fi

cat > "${CONFIG_FILE}" <<EOF
[DedicatedServer]
OwnerID=${OWNER_ID}
ServerName=${SERVER_NAME}
DefaultWorldName=${DEFAULT_WORLD_NAME:-${SERVER_NAME}}
AdminPassword=${ADMIN_PASSWORD:-changeme}
WorldPassword=${WORLD_PASSWORD:-}
EOF

echo "[entrypoint] Config written to ${CONFIG_FILE}:"
cat "${CONFIG_FILE}"

# --- Determine the server binary ---
cd "${SERVER_DIR}"

if [ -f "./RSDragonwildsServer.sh" ]; then
    SERVER_BIN="./RSDragonwildsServer.sh"
elif [ -f "./RSDragonwilds.sh" ]; then
    SERVER_BIN="./RSDragonwilds.sh"
else
    echo "[entrypoint] Looking for server binary..."
    SERVER_BIN=$(find . -maxdepth 1 -name "*.sh" -executable | head -1)
    if [ -z "${SERVER_BIN}" ]; then
        echo "[entrypoint] ERROR: No executable .sh found in ${SERVER_DIR}. Listing contents:"
        ls -la "${SERVER_DIR}"
        exit 1
    fi
fi

echo "[entrypoint] Starting server with: ${SERVER_BIN}"
exec ${SERVER_BIN} -log "$@"
