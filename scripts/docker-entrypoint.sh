#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

# Always recursively chown /paperclip on boot. Railway mounts volumes
# as root, and any files written to the volume from a `railway ssh` session
# (which runs as root) will also be root-owned. Fixing this every boot
# keeps the node user able to read/write its instance dir regardless of
# how files got there.
chown -R node:node /paperclip

exec gosu node "$@"
