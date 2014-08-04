#!/usr/bin/env bash
set -e

resolve_link() {
  $(type -p greadlink readlink | head -1) "$1"
}

abs_dirname() {
  local cwd="$(pwd)"
  local path="$1"

  while [ -n "$path" ]; do
    cd "${path%/*}"
    local name="${path##*/}"
    path="$(resolve_link "$name" || true)"
  done

  pwd
  cd "$cwd"
}

PREFIX="$1"
if [ -z "$1" ]; then
  { echo "usage: $0 <prefix>"
    echo "  e.g. $0 /usr/local"
  } >&2
  exit 1
fi

BATS_ROOT="$(abs_dirname "$0")"
echo $BATS_ROOT
mkdir -p "$PREFIX"/bin
cp -f "$BATS_ROOT"/*.bats "$PREFIX"/bin
cp -f "$BATS_ROOT"/*.bash "$PREFIX"/bin

echo "Installed Foreman BATS into $PREFIX/bin"
