#!/bin/bash
set -e

SERVER_DIR="${SERVER_DIR:-/opt/dragonwilds}"
SERVER_APP_ID=4019830

CONFIG_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer"
CONFIG_FILE="${CONFIG_DIR}/DedicatedServer.ini"
SAVEGAMES_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Savegames"
LOGS_DIR="${SERVER_DIR}/RSDragonwilds/Saved/Logs"
SERVER_EXEC="${SERVER_DIR}/RSDragonwilds/Binaries/Linux/RSDragonwildsServer-Linux-Shipping"

DEFAULT_PORT="${DEFAULT_PORT:-7777}"
MAX_PLAYERS="${MAX_PLAYERS:-6}"

# --- Install / update server via DepotDownloader (anonymous, no login) ---
if [ "${UPDATE_ON_START}" != "false" ]; then
    echo "[entrypoint] Installing/updating dedicated server (app ${SERVER_APP_ID})..."
    /depotdownloader/DepotDownloader \
        -app ${SERVER_APP_ID} \
        -os linux \
        -dir "${SERVER_DIR}" \
        -validate
    echo "[entrypoint] Update complete."
fi

# --- Fix ownership & permissions ---
chown -R steam:steam "${SERVER_DIR}"
chmod +x "${SERVER_EXEC}" 2>/dev/null || true
chmod +x "${SERVER_DIR}/RSDragonwilds/Plugins/Developer/Sentry/Binaries/Linux/crashpad_handler" 2>/dev/null || true

# --- Validate required env vars ---
if [ -z "${OWNER_ID}" ]; then
    echo "[entrypoint] ERROR: OWNER_ID is required."
    echo "[entrypoint] Find your Player ID in-game at the bottom of the Settings Menu."
    exit 1
fi

# --- Create directories ---
mkdir -p "${CONFIG_DIR}" "${SAVEGAMES_DIR}" "${LOGS_DIR}"

# --- Write DedicatedServer.ini with correct UE INI format ---
echo "[entrypoint] Writing ${CONFIG_FILE}"
cat > "${CONFIG_FILE}" << EOF
[SectionsToSave]
bCanSaveAllSections=true

[/Script/Dominion.DedicatedServerSettings]
AdminPassword=${ADMIN_PASSWORD:-changeme}
OwnerId=${OWNER_ID}
WorldPassword=${WORLD_PASSWORD:-}
ServerName=${SERVER_NAME:-DragonWildsServer}
DefaultWorldName=${DEFAULT_WORLD_NAME:-${SERVER_NAME:-MyWorld}}
ServerGuid=
EOF
chown steam:steam "${CONFIG_FILE}"

echo "[entrypoint] Config written:"
cat "${CONFIG_FILE}"

# --- Verify server binary exists ---
if [ ! -f "${SERVER_EXEC}" ]; then
    echo "[entrypoint] ERROR: Server binary not found at ${SERVER_EXEC}"
    echo "[entrypoint] Contents of ${SERVER_DIR}:"
    ls -la "${SERVER_DIR}"
    exit 1
fi

# --- Launch ---
echo "[entrypoint] Starting server on port ${DEFAULT_PORT} (UDP)"
echo "[entrypoint] Server name: ${SERVER_NAME}"
echo "[entrypoint] Default world: ${DEFAULT_WORLD_NAME}"

LAUNCH_ARGS="RSDragonwilds -log -NewConsole -Port=${DEFAULT_PORT} -ini:Game:[/Script/Engine.GameSession]:MaxPlayers=${MAX_PLAYERS}"

exec gosu steam "${SERVER_EXEC}" ${LAUNCH_ARGS} "$@"
