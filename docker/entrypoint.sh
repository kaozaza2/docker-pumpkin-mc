#!/bin/sh
# POSIX sh on purpose: bash makes $UID readonly and ignores the env value.
set -eu

: "${UID:=1000}" "${GID:=1000}"
CONFIG=pumpkin.toml

log() { echo "[init] $*"; }

if [ "$(id -u)" = 0 ]; then
  find /data \( \! -user "$UID" -o \! -group "$GID" \) -exec chown -h "$UID:$GID" {} +
  exec su-exec "$UID:$GID" "$0" "$@"
fi

# env var | toml key | kind (str, raw, enum, port)
SETTINGS='
MOTD                networking.java.motd                  str
MAX_PLAYERS         networking.java.max_players           raw
ONLINE_MODE         networking.java.online_mode           raw
VIEW_DISTANCE       networking.java.view_distance         raw
SIMULATION_DISTANCE networking.java.simulation_distance   raw
SERVER_PORT         networking.java.address               port
ENABLE_BEDROCK      networking.bedrock.enabled            raw
BEDROCK_PORT        networking.bedrock.nethernet.address  port
ENABLE_QUERY        networking.query.enabled              raw
DIFFICULTY          default_difficulty                    enum
MODE                default_gamemode                      enum
FORCE_GAMEMODE      force_gamemode                        raw
HARDCORE            hardcore                              raw
SEED                seed                                  str
LEVEL               default_level_name                    str
ALLOW_NETHER        allow_nether                          raw
ALLOW_END           allow_end                             raw
ENABLE_WHITELIST    white_list                            raw
ENFORCE_WHITELIST   enforce_whitelist                     raw
SPAWN_PROTECTION    spawn_protection                      raw
OP_PERMISSION_LEVEL op_permission_level                   raw
PVP                 pvp.enabled                           raw
LOG_LEVEL           logging.level                         str
'

set_config() {
  key=$1 kind=$2 value=$3
  case $kind in
    enum) value="$(printf %s "$value" | cut -c1 | tr a-z A-Z)$(printf %s "$value" | cut -c2- | tr A-Z a-z)" ;;
    port) value="0.0.0.0:$value" ;;
    raw) value=$(printf %s "$value" | tr A-Z a-z) ;;
  esac
  [ "$kind" = raw ] && expr="env(V)" || expr="strenv(V)"
  V=$value yq -i -p toml -o toml ".$key = $expr" "$CONFIG"
  log "$key = $value"
}

[ -f "$CONFIG" ] || : >"$CONFIG"

echo "$SETTINGS" | while read -r var key kind; do
  [ -n "$var" ] || continue
  eval "value=\${$var-}"
  if [ -n "$value" ]; then set_config "$key" "$kind" "$value"; fi
done

# CFG_NETWORKING__JAVA__PACKET_LIMITER__ENABLED=false -> networking.java.packet_limiter.enabled
env | sed -n 's/^CFG_\([A-Z0-9_]*\)=.*/\1/p' | while read -r name; do
  eval "value=\${CFG_$name}"
  set_config "$(echo "$name" | tr A-Z a-z | sed 's/__/./g')" raw "$value"
done

player_uuid() {
  if [ "${ONLINE_MODE:-true}" = false ]; then
    h=$(printf 'OfflinePlayer:%s' "$1" | md5sum | cut -c1-32)
    b6=$(printf %02x $(( (0x$(echo "$h" | cut -c13-14) & 0x0f) | 0x30 )))
    b8=$(printf %02x $(( (0x$(echo "$h" | cut -c17-18) & 0x3f) | 0x80 )))
    h="$(echo "$h" | cut -c1-12)$b6$(echo "$h" | cut -c15-16)$b8$(echo "$h" | cut -c19-32)"
  else
    h=$(curl -fsS "https://api.minecraftservices.com/minecraft/profile/lookup/name/$1" | jq -r .id) || return 1
  fi
  echo "$h" | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/'
}

# Adds comma-separated players missing from a JSON list file; existing entries are kept.
add_players() {
  file=$1 names=$2 extra=$3
  [ -s "$file" ] || echo '[]' >"$file"
  for name in $(echo "$names" | tr ',' ' '); do
    jq -e --arg n "$name" 'any(.[]; (.name | ascii_downcase) == ($n | ascii_downcase))' "$file" >/dev/null && continue
    if ! uuid=$(player_uuid "$name"); then
      log "could not resolve $name, skipping"
      continue
    fi
    jq --arg n "$name" --arg u "$uuid" ". + [{uuid: \$u, name: \$n} + $extra]" "$file" >"$file.tmp" && mv "$file.tmp" "$file"
    log "added $name ($uuid) to $file"
  done
}

if [ -n "${OPS:-}" ]; then add_players ops.json "$OPS" "{level: ${OP_PERMISSION_LEVEL:-4}, bypassesPlayerLimit: false}"; fi
if [ -n "${WHITELIST:-}" ]; then add_players whitelist.json "$WHITELIST" '{}'; fi

exec pumpkin "$@"
