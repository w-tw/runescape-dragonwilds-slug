# RuneScape: Dragonwilds - Dedicated Server (Docker)

Dockerized dedicated server for [RuneScape: Dragonwilds](https://dragonwilds.runescape.com/news/how-to-dedicated-servers). Uses DepotDownloader for anonymous downloads (no Steam login required) and auto-updates on each container start.

## Requirements

- Docker & Docker Compose
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
| `OWNER_ID` | Yes | Your in-game Player ID |
| `SERVER_NAME` | Yes | Public server name |
| `ADMIN_PASSWORD` | Yes | Password for in-game admin panel |
| `DEFAULT_WORLD_NAME` | No | World name (defaults to `MyWorld`) |
| `WORLD_PASSWORD` | No | Password to join the world (empty = public) |
| `DEFAULT_PORT` | No | UDP port (default: `7777`) |
| `MAX_PLAYERS` | No | Max players, 2GB + 1GB each (default: `6`) |
| `UPDATE_ON_START` | No | Auto-update on start (default: `true`) |

3. **Build and start**

```bash
docker compose up -d --build
```

First start will download ~2 GB of server files. Watch progress with:

```bash
docker compose logs -f dragonwilds
```

4. **Find your server in-game** -- go to the **Public** tab of the Worlds screen, search your exact `SERVER_NAME` (case-sensitive), and join.

## Updating

The server auto-updates on every container start. To restart and pull the latest version:

```bash
docker compose restart
```

To skip auto-update, set `UPDATE_ON_START=false` in your `.env`.

## Volumes

| Volume | Container Path | Purpose |
|---|---|---|
| `server-files` | `/opt/dragonwilds` | Game server installation |
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
docker compose cp dragonwilds-server:/opt/dragonwilds/RSDragonwilds/Saved/Savegames ./backups/
```

## Logs

View live server logs:

```bash
docker compose logs -f dragonwilds
```

## Memory

The `mem_limit` in `docker-compose.yml` is set to **8 GB** (enough for 6 players). Adjust based on your expected player count: **2 GB base + 1 GB per player**.

## Ports

The server uses UDP port **7777** by default. If you change `DEFAULT_PORT` in `.env`, update the port mapping in `docker-compose.yml` to match.

## Troubleshooting

- **Server not showing in list** -- check that UDP 7777 is open on your firewall and forwarded by your router.
- **Version mismatch** -- restart the container to trigger an auto-update: `docker compose restart`.
- **Can't join** -- port forwarding likely failed somewhere between you and your ISP. Check [portforward.com](http://portforward.com/) for router-specific guides.
- **Binary not found** -- check `docker compose logs` for details; the entrypoint prints the directory listing on failure.
- **Config not read** -- the server reads `RSDragonwilds/Saved/Config/LinuxServer/DedicatedServer.ini`. The entrypoint writes this automatically from your `.env` values.

## Reference

- [Official Dedicated Server Guide](https://dragonwilds.runescape.com/news/how-to-dedicated-servers)
- [RuneScape: Dragonwilds Wiki](https://dragonwilds.runescape.wiki/)
- [indifferentbroccoli Docker Image](https://github.com/indifferentbroccoli/runescape-dragonwilds-server-docker)
- [Community Debian Setup Guide](https://github.com/Skerlord/Runescape-Dragonwilds-DebianSetup)
