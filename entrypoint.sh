#!/bin/bash
set -e

SAVED_DIR="${SERVER_DIR}/RSDragonwilds/Saved"
CONFIG_DIR_A="${SAVED_DIR}/Config/LinuxServer"
CONFIG_DIR_B="${SAVED_DIR}/Config/Linux"
BACKUP_DIR="${SERVER_DIR}/config_backups"
SAVEGAMES_DIR="${SAVED_DIR}/Savegames"
LOGS_DIR="${SAVED_DIR}/Logs"

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
for dir in "${CONFIG_DIR_A}" "${CONFIG_DIR_B}"; do
    if [ -f "${dir}/DedicatedServer.ini" ]; then
        echo "[entrypoint] Backing up ${dir}/DedicatedServer.ini"
        cp "${dir}/DedicatedServer.ini" "${BACKUP_DIR}/DedicatedServer.ini.bak"
    fi
done

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
    for dir in "${CONFIG_DIR_A}" "${CONFIG_DIR_B}"; do
        mkdir -p "${dir}"
        cp "${BACKUP_DIR}/DedicatedServer.ini.bak" "${dir}/DedicatedServer.ini"
    done
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
mkdir -p "${CONFIG_DIR_A}" "${CONFIG_DIR_B}" "${SAVEGAMES_DIR}" "${LOGS_DIR}"

# --- Validate required env vars ---
if [ -z "${OWNER_ID}" ]; then
    echo "[entrypoint] ERROR: OWNER_ID is required. Find it in-game at Settings > bottom of menu."
    exit 1
fi
if [ -z "${SERVER_NAME}" ]; then
    echo "[entrypoint] ERROR: SERVER_NAME is required."
    exit 1
fi

# --- Build config content (no section header -- game uses custom parser) ---
CONFIG_CONTENT="Owner ID=${OWNER_ID}
Server Name=${SERVER_NAME}
Default World Name=${DEFAULT_WORLD_NAME:-${SERVER_NAME}}
Admin Password=${ADMIN_PASSWORD:-changeme}
World Password=${WORLD_PASSWORD:-}"

# --- Write to BOTH possible config paths ---
for dir in "${CONFIG_DIR_A}" "${CONFIG_DIR_B}"; do
    INI="${dir}/DedicatedServer.ini"
    echo "[entrypoint] Writing config to ${INI}..."
    echo "${CONFIG_CONTENT}" > "${INI}"
    chown steam:steam "${INI}"
    echo "[entrypoint] Verifying ${INI}..."
    ls -la "${INI}"
    cat "${INI}"
done

echo "[entrypoint] All config files written."

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
