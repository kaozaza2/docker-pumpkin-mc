#!/bin/sh
set -eu

if [ $# -eq 0 ]; then
  echo "usage: send-command <command...>" >&2
  exit 1
fi
if [ ! -p "$CONSOLE_PIPE" ]; then
  echo "server console is not running" >&2
  exit 1
fi
printf '%s\n' "$*" >"$CONSOLE_PIPE"
