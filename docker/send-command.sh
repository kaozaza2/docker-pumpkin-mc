#!/bin/sh
set -eu

quiet=false
if [ "${1:-}" = -q ]; then
  quiet=true
  shift
fi
if [ $# -eq 0 ]; then
  echo "usage: send-command [-q] <command...>" >&2
  exit 1
fi
if [ ! -p "$CONSOLE_DIR/input" ]; then
  echo "server console is not running" >&2
  exit 1
fi

if $quiet; then
  printf '%s\n' "$*" >"$CONSOLE_DIR/input"
  exit 0
fi

capture=$(mktemp "$CONSOLE_DIR/capture.XXXXXX")
trap 'rm -f "$capture"' EXIT
chmod 666 "$capture"
printf '%s\n' "$*" >"$CONSOLE_DIR/input"

# Wait up to 3s, stopping once output has been quiet for 0.3s.
seen=0 idle=0
for _ in $(seq 30); do
  sleep 0.1
  size=$(wc -c <"$capture")
  if [ "$size" -gt "$seen" ]; then
    seen=$size idle=0
  elif [ "$seen" -gt 0 ] && [ $((idle += 1)) -ge 3 ]; then
    break
  fi
done
cat "$capture"
