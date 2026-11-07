#!/usr/bin/env bash
# Write a saved image back to the radio and confirm it arrived.
# usage: ./restore.sh images/backup-....img
source "$(dirname "$0")/common.sh"

if [[ $# -ne 1 || ! -f "$1" ]]; then
    echo "usage: $0 <image.img>" >&2
    exit 1
fi
image="$1"
PORT="$(find_port)"
readback="$IMAGES/readback-$STAMP.img"

read -r -p "Replace everything on the radio with $image? Type yes to continue: " answer
if [[ "$answer" != "yes" ]]; then
    echo "Stopped. The radio was not changed."
    exit 1
fi
write_radio "$image"
echo
echo "Now read it back to confirm."
read_radio "$readback"
if ! cmp -s "$image" "$readback"; then
    TOOLS="$ROOT/tools" "$PY" - "$image" "$readback" <<'PY'
import os
import sys
sys.path.insert(0, os.environ['TOOLS'])
from ft60_link import load_image
a, b = (load_image(p).get_mmap().get_packed() for p in sys.argv[1:3])
sys.exit('RESTORE FAILED: radio does not match the image' if a != b else 0)
PY
fi
echo "RESTORE OK. Turn the radio off and on to leave clone mode."
