#!/bin/bash
# RemoveMacAI: debloat macOS, starting with Apple Intelligence and its models.
#
#   curl -fsSL https://raw.githubusercontent.com/omlahore/RemoveMacAI/main/install.sh | bash
#
# Undo everything later with the same line plus "-s revert":
#
#   curl -fsSL https://raw.githubusercontent.com/omlahore/RemoveMacAI/main/install.sh | bash -s revert
#
# It downloads the latest release, checks its SHA-256, runs it from a temporary
# folder and deletes it afterwards. Nothing is installed.
#
# To install the app in Applications instead and open it:
#
#   curl -fsSL https://raw.githubusercontent.com/omlahore/RemoveMacAI/main/install.sh | bash -s app
set -euo pipefail

self="curl -fsSL https://raw.githubusercontent.com/omlahore/RemoveMacAI/main/install.sh | bash"
base="${REMOVEMACAI_URL:-https://github.com/omlahore/RemoveMacAI/releases/latest/download}"
asset="removemacai-darwin-arm64.tar.gz"
# The repository whose release workflow must have built the download.
repo="${REMOVEMACAI_REPO:-omlahore/RemoveMacAI}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "RemoveMacAI is for macOS." >&2
  exit 1
fi
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" != "1" ]; then
  echo "Apple Intelligence only runs on Apple silicon Macs, so there is nothing to remove here." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Downloads a release file and its checksum, and stops unless they match.
fetch() {
  curl -fsSL "$base/$1" -o "$tmp/$1"
  curl -fsSL "$base/$1.sha256" -o "$tmp/$1.sha256"
  expected="$(awk '{print $1}' "$tmp/$1.sha256")"
  actual="$(shasum -a 256 "$tmp/$1" | awk '{print $1}')"
  if [ "$expected" != "$actual" ]; then
    echo "The download does not match its checksum, so it was not used." >&2
    exit 1
  fi
  verify_provenance "$tmp/$1"
}

# The checksum comes from the same release as the file, so it only catches a
# damaged download. The build attestation proves the file was built from the
# repository's workflow. It is checked when the GitHub CLI is installed, and
# required when REMOVEMACAI_VERIFY=1.
verify_provenance() {
  if command -v gh >/dev/null 2>&1; then
    if ! gh attestation verify "$1" --repo "$repo" >/dev/null 2>&1; then
      echo "The download has no valid build attestation from $repo, so it was not used. (gh needs to be signed in: gh auth login)" >&2
      exit 1
    fi
  elif [ "${REMOVEMACAI_VERIFY:-0}" = "1" ]; then
    echo "REMOVEMACAI_VERIFY=1 needs the GitHub CLI (gh) to check the build attestation." >&2
    exit 1
  else
    echo "Note: install the GitHub CLI (gh) to also verify the build attestation." >&2
  fi
}

if [ "${1:-}" = "app" ]; then
  fetch RemoveMacAI.zip
  ditto -x -k "$tmp/RemoveMacAI.zip" "$tmp/app"
  dest="/Applications"
  [ -w "$dest" ] || dest="$HOME/Applications"
  mkdir -p "$dest"
  rm -rf "$dest/RemoveMacAI.app"
  ditto "$tmp/app/RemoveMacAI.app" "$dest/RemoveMacAI.app"
  echo "Installed $dest/RemoveMacAI.app"
  open "$dest/RemoveMacAI.app"
  exit 0
fi

fetch "$asset"
tar -xzf "$tmp/$asset" -C "$tmp"

export REMOVEMACAI_UNDO="$self -s revert"
if (exec < /dev/tty) 2>/dev/null; then
  "$tmp/removemacai" "$@" < /dev/tty
else
  "$tmp/removemacai" "$@"
fi
