#!/usr/bin/env bash
# Read the radio and compare it with the CSV. Changes nothing on the radio.
# usage: ./verify.sh [channels.csv]
source "$(dirname "$0")/common.sh"

CSV="${1:-$CSV}"
PORT="$(find_port)"
out="$IMAGES/readback-$STAMP.img"
read_radio "$out"
tool verify_image "$out" "$CSV"
