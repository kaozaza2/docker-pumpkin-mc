# Pumpkin server in Docker

`ghcr.io/kaozaza2/docker-pumpkin-mc` for `linux/amd64` and `linux/arm64`, rebuilt daily from the Pumpkin nightly release.

A Docker image for [Pumpkin](https://github.com/Pumpkin-MC/Pumpkin), configured with environment variables the way [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) is.

```sh
docker compose pull && docker compose up -d   # prebuilt image from ghcr.io
docker compose up -d --build                   # or build locally
docker compose logs -f
docker attach minecraft-server-mc-1   # server console; detach with Ctrl-P Ctrl-Q
```

Server files (`pumpkin.toml`, `world/`, `ops.json`, ...) live in `./data`. Env vars are applied to `pumpkin.toml` on every start. Anything you don't set stays as it is in the file.

## Build options

Clone with `--recurse-submodules` if you want `PUMPKIN_SOURCE=source`; `pumpkin/` is a submodule of the upstream repo.

| Build arg | Default | Meaning |
|---|---|---|
| `PUMPKIN_SOURCE` | `release` | `release` downloads a prebuilt binary; `source` compiles `./pumpkin` |
| `PUMPKIN_VERSION` | `nightly` | Release tag to download, e.g. `0.2.1+26.3-26.51` |

## Environment variables

| Variable | `pumpkin.toml` key | Example |
|---|---|---|
| `MOTD` | `networking.java.motd` | `My server` |
| `MAX_PLAYERS` | `networking.java.max_players` | `20` |
| `ONLINE_MODE` | `networking.java.online_mode` | `false` |
| `VIEW_DISTANCE` | `networking.java.view_distance` | `10` |
| `SIMULATION_DISTANCE` | `networking.java.simulation_distance` | `10` |
| `SERVER_PORT` | `networking.java.address` | `25565` |
| `ENABLE_BEDROCK` | `networking.bedrock.enabled` | `false` |
| `BEDROCK_PORT` | `networking.bedrock.nethernet.address` | `19132` |
| `ENABLE_QUERY` | `networking.query.enabled` | `true` |
| `DIFFICULTY` | `default_difficulty` | `peaceful`, `easy`, `normal`, `hard` |
| `MODE` | `default_gamemode` | `survival`, `creative`, `adventure`, `spectator` |
| `FORCE_GAMEMODE` | `force_gamemode` | `true` |
| `HARDCORE` | `hardcore` | `true` |
| `SEED` | `seed` | `12345` or text |
| `LEVEL` | `default_level_name` | `world` |
| `ALLOW_NETHER` / `ALLOW_END` | `allow_nether` / `allow_end` | `false` |
| `ENABLE_WHITELIST` | `white_list` | `true` |
| `ENFORCE_WHITELIST` | `enforce_whitelist` | `true` |
| `SPAWN_PROTECTION` | `spawn_protection` | `0` |
| `OP_PERMISSION_LEVEL` | `op_permission_level` (also the level given to `OPS`) | `4` |
| `PVP` | `pvp.enabled` | `false` |
| `LOG_LEVEL` | `logging.level` | `debug` |

Any other key: `CFG_<PATH>` with `__` between levels, e.g. `CFG_NETWORKING__JAVA__PACKET_LIMITER__ENABLED=false`.

Other variables:

- `OPS`, `WHITELIST`: comma-separated player names to add to `ops.json` / `whitelist.json`. Names are only ever added, never removed. With online mode, UUIDs come from the Mojang API; with `ONLINE_MODE=false`, offline UUIDs are used.
- `UID`, `GID` (default `1000`): the user the server runs as. `/data` is chowned to it at startup.
- `TZ`: timezone for log timestamps, e.g. `Asia/Bangkok`.

Arguments after the image name are passed to `pumpkin` (for example `--convert-world`).
