#!/bin/bash
set -e

CONFIG_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Config/Linux"
CONFIG_FILE="${CONFIG_DIR}/DedicatedServer.ini"
SAVEGAMES_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Savegames"
LOGS_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Logs"

# --- Update server on every start ---
if [ "${UPDATE_ON_START}" != "false" ]; then
    echo "[entrypoint] Updating dedicated server (app ${SERVER_APP_ID})..."
    steamcmd \
        +force_install_dir "${SERVER_DIR}" \
        +login anonymous \
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

# --- Launch server ---
echo "[entrypoint] Starting RuneScape: Dragonwilds Dedicated Server..."
cd "${SERVER_DIR}"

exec ./RSDragonwilds.sh -log -NewConsole "$@"
