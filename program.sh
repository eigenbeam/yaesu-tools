#!/usr/bin/env bash
# Back up the radio, apply the CSV, write it, then read it back and check it.
# usage: ./program.sh [--prune]
#   --prune also empties every memory with no row in the CSV.
source "$(dirname "$0")/common.sh"

prune=()
if [[ "${1:-}" == "--prune" ]]; then
    prune=(--prune)
fi

PORT="$(find_port)"
backup="$IMAGES/backup-$STAMP-before-programming.img"
new="$IMAGES/new-$STAMP.img"
readback="$IMAGES/readback-$STAMP.img"

echo "=== Step 1 of 4: back up the radio ==="
read_radio "$backup"

echo
echo "=== Step 2 of 4: build the new image ==="
tool apply_csv "$CSV" "$backup" "$new" ${prune[@]+"${prune[@]}"}
tool verify_image "$new" "$CSV"
read -r -p "Write this to the radio? Type yes to continue: " answer
if [[ "$answer" != "yes" ]]; then
    echo "Stopped. The radio was not changed."
    exit 1
fi

echo
echo "=== Step 3 of 4: write to the radio ==="
write_radio "$new"

echo
echo "=== Step 4 of 4: read back and verify ==="
read_radio "$readback"
tool verify_image "$readback" "$CSV" "$new"
echo
echo "Done. Turn the radio off and on to leave clone mode. Backup: $backup"
