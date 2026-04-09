# RuneScape: Dragonwilds - Dedicated Server (Docker)

Dockerized dedicated server for [RuneScape: Dragonwilds](https://dragonwilds.runescape.com/news/how-to-dedicated-servers), using SteamCMD to install and auto-update the server on each container start.

## Requirements

- Docker & Docker Compose
- A **Steam account** that owns RuneScape: Dragonwilds (anonymous download is not supported for this app)
- UDP port **7777** open on your firewall/router
- Your RuneScape: Dragonwilds **Player ID** (found in-game: Settings > bottom of menu)

## Quick Start

1. **Clone this repo**

```bash
git clone https://github.com/YOUR_USER/runescape-dragonwilds-slug.git
cd runescape-dragonwilds-slug
```

2. **Create your `.env` file**

```bash
cp .env.example .env
```

Edit `.env` and fill in your values:

| Variable | Required | Description |
|---|---|---|
| `STEAM_USER` | Yes | Steam account username |
| `STEAM_PASS` | Yes | Steam account password |
| `OWNER_ID` | Yes | Your in-game Player ID |
| `SERVER_NAME` | Yes | Public server name |
| `DEFAULT_WORLD_NAME` | No | World name (defaults to `SERVER_NAME`) |
| `ADMIN_PASSWORD` | No | Password for in-game admin panel (default: `changeme`) |
| `WORLD_PASSWORD` | No | Password to join the world (empty = public) |

3. **Build and start**

```bash
docker compose up -d --build
```

4. **Find your server in-game** -- go to the **Public** tab of the Worlds screen, search your exact `SERVER_NAME` (case-sensitive), and join.

## Steam Guard / 2FA

If your Steam account uses Steam Guard, the first run will fail because SteamCMD needs the auth code. To handle this:

```bash
# Run interactively the first time
docker compose run --rm dragonwilds bash

# Inside the container, run SteamCMD manually:
steamcmd +force_install_dir /opt/dragonwilds +login YOUR_STEAM_USER +quit
# Enter your Steam Guard code when prompted.
# After success, exit the container.
exit

# Now start normally -- the auth token is cached in the steam-data volume
docker compose up -d --build
```

## Updating

The server auto-updates on every container start by default. To restart and pull the latest version:

```bash
docker compose restart
```

To disable auto-update, set `UPDATE_ON_START=false` in `docker-compose.yml`.

## Volumes

| Volume | Container Path | Purpose |
|---|---|---|
| `server-files` | `/opt/dragonwilds` | Game server installation |
| `steam-data` | `/root/.local/share/Steam` | SteamCMD auth tokens & cache |
| `savegames` | `.../Saved/Savegames` | World save files |
| `logs` | `.../Saved/Logs` | Server logs |

## Managing Worlds

### Upload an existing world

1. Stop the server: `docker compose down`
2. Copy your `.sav` file into the savegames volume:
   ```bash
   docker compose run --rm dragonwilds bash -c "cp /tmp/myworld.sav /opt/dragonwilds/RSDragonwilds/Saved/Savegames/"
   ```
3. Start the server: `docker compose up -d`

### Backup saves

```bash
docker compose cp dragonwilds:/opt/dragonwilds/RSDragonwilds/Saved/Savegames ./backups/
```

## Logs

View live server logs:

```bash
docker compose logs -f dragonwilds
```

## Memory

The `mem_limit` in `docker-compose.yml` is set to **8 GB** (enough for 6 players). Adjust based on your expected player count: **2 GB base + 1 GB per player**.

## Ports

The server uses UDP port **7777** by default. If you need to change it, update the `ports` mapping in `docker-compose.yml`.

## Troubleshooting

- **"Missing configuration" from SteamCMD** -- anonymous login does not work; make sure `STEAM_USER` and `STEAM_PASS` are set in `.env`.
- **Steam Guard prompt** -- see the Steam Guard section above for first-run interactive auth.
- **Server not showing in list** -- check that UDP 7777 is open on your firewall and forwarded by your router.
- **Version mismatch** -- restart the container to trigger an auto-update: `docker compose restart`.
- **Can't join** -- port forwarding likely failed somewhere between you and your ISP. Check [portforward.com](http://portforward.com/) for router-specific guides.
- **Binary not found** -- the entrypoint auto-detects the server binary; check `docker compose logs` for the directory listing it prints on failure.

## Reference

- [Official Dedicated Server Guide](https://dragonwilds.runescape.com/news/how-to-dedicated-servers)
- [RuneScape: Dragonwilds Wiki](https://dragonwilds.runescape.wiki/)
- [Community Debian Setup Guide](https://github.com/Skerlord/Runescape-Dragonwilds-DebianSetup)
