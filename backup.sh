#!/usr/bin/env bash
# Save everything in the radio to images/. Reads only; changes nothing on the radio.
# usage: ./backup.sh [label]
source "$(dirname "$0")/common.sh"

PORT="$(find_port)"
out="$IMAGES/backup-$STAMP${1:+-$1}.img"
read_radio "$out"
echo "Backup saved: $out"
