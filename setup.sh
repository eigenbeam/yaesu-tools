#!/usr/bin/env bash
# Install CHIRP from source. Pinned to the commit this project was tested with.
set -euo pipefail

CHIRP_COMMIT=b9a5b35e7e2a0768d94c9b3c46215bc792e31011

if ! command -v uv >/dev/null; then
    echo "uv is required: https://docs.astral.sh/uv/getting-started/installation/" >&2
    exit 1
fi
uv tool install --force --python 3.13 "git+https://github.com/kk7ds/chirp.git@$CHIRP_COMMIT"
echo "CHIRP installed."
ls /dev/cu.usbserial-* 2>/dev/null || echo "Cable not detected. Plug it in to check."
