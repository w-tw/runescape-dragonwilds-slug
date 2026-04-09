#!/bin/bash
set -e

CONFIG_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer"
CONFIG_FILE="${CONFIG_DIR}/DedicatedServer.ini"
BACKUP_DIR="${SERVER_DIR}/config_backups"
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

# --- Backup config before update (validate can wipe it) ---
mkdir -p "${BACKUP_DIR}"
if [ -f "${CONFIG_FILE}" ]; then
    echo "[entrypoint] Backing up existing config..."
    cp "${CONFIG_FILE}" "${BACKUP_DIR}/DedicatedServer.ini.bak"
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

# --- Restore config after update ---
if [ -f "${BACKUP_DIR}/DedicatedServer.ini.bak" ]; then
    echo "[entrypoint] Restoring config from backup..."
    mkdir -p "${CONFIG_DIR}"
    cp "${BACKUP_DIR}/DedicatedServer.ini.bak" "${CONFIG_FILE}"
fi

# --- Copy Steam SDK files (required by some UE servers) ---
if [ ! -f "${SERVER_DIR}/.steam/sdk32/steamclient.so" ]; then
    mkdir -p "${SERVER_DIR}/.steam/sdk32"
    cp -R /usr/lib/games/steam/steamcmd/linux32/* "${SERVER_DIR}/.steam/sdk32/" 2>/dev/null || true
fi
if [ ! -f "${SERVER_DIR}/.steam/sdk64/steamclient.so" ]; then
    mkdir -p "${SERVER_DIR}/.steam/sdk64"
    cp -R /usr/lib/games/steam/steamcmd/linux64/* "${SERVER_DIR}/.steam/sdk64/" 2>/dev/null || true
fi

# --- Fix ownership ---
chown -R steam:steam "${SERVER_DIR}"

# --- Create directories ---
mkdir -p "${CONFIG_DIR}" "${SAVEGAMES_DIR}" "${LOGS_DIR}"

# --- Validate required env vars ---
if [ -z "${OWNER_ID}" ]; then
    echo "[entrypoint] ERROR: OWNER_ID is required. Find it in-game at Settings > bottom of menu."
    exit 1
fi
if [ -z "${SERVER_NAME}" ]; then
    echo "[entrypoint] ERROR: SERVER_NAME is required."
    exit 1
fi

# --- Write DedicatedServer.ini ---
echo "[entrypoint] Writing config to ${CONFIG_FILE}..."

cat > "${CONFIG_FILE}" <<EOF
[DedicatedServer]
OwnerId=${OWNER_ID}
ServerName=${SERVER_NAME}
DefaultWorldName=${DEFAULT_WORLD_NAME:-${SERVER_NAME}}
AdminPassword=${ADMIN_PASSWORD:-changeme}
WorldPassword=${WORLD_PASSWORD:-}
EOF

chown steam:steam "${CONFIG_FILE}"

echo "[entrypoint] Config contents:"
cat "${CONFIG_FILE}"

# --- Verify file was written ---
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "[entrypoint] ERROR: Failed to write config file!"
    exit 1
fi
echo "[entrypoint] Config file verified at ${CONFIG_FILE}"

# --- Determine the server binary ---
cd "${SERVER_DIR}"

SERVER_BIN=""
if [ -f "./RSDragonwildsServer.sh" ]; then
    SERVER_BIN="./RSDragonwildsServer.sh"
elif [ -f "./RSDragonwilds.sh" ]; then
    SERVER_BIN="./RSDragonwilds.sh"
fi

if [ -z "${SERVER_BIN}" ]; then
    echo "[entrypoint] ERROR: No server binary found. Listing ${SERVER_DIR}:"
    ls -la "${SERVER_DIR}"
    exit 1
fi

chmod +x "${SERVER_BIN}"

echo "[entrypoint] Starting server as user 'steam' with: ${SERVER_BIN}"
exec gosu steam ${SERVER_BIN} -log -Port=7777 "$@"
