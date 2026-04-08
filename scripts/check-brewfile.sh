#!/bin/sh

usage() {
  echo "Usage: $0 [-v] [-s]" >&2
  exit 1
}

while getopts "hvs" opt; do
  case "$opt" in
    v) verbose=1 ;;
    s) silent=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

[ "$silent" ] && exec >/dev/null

while IFS= read -r line; do
  case "$line" in
    'brew '*)
      item="${line#brew }"
      item="${item%\"}"
      item="${item#\"}"
      if [ "$verbose" ]; then
        brew info "$item" || { echo "$item" >&2; exit 1; }
      else
        brew info "$item" >/dev/null 2>&1 || { echo "$item" >&2; exit 1; }
      fi
      ;;
    'cask '*)
      item="${line#cask }"
      item="${item%\"}"
      item="${item#\"}"
      if [ "$verbose" ]; then
        brew info --cask "$item" || { echo "$item" >&2; exit 1; }
      else
        brew info --cask "$item" >/dev/null 2>&1 || { echo "$item" >&2; exit 1; }
      fi
      ;;
  esac
done < "${0%/*}/../Brewfile"