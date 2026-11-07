# Shared by the other scripts. Not meant to be run directly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES="$ROOT/images"
CSV="${CSV:-$ROOT/ft60r-evarc-channels.csv}"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
export PYTHONWARNINGS=ignore

python_for_chirp() {
    local py
    py="$(uv tool dir 2>/dev/null)/chirp/bin/python"
    if [[ ! -x "$py" ]]; then
        echo "CHIRP is not installed. Run ./setup.sh first." >&2
        exit 1
    fi
    echo "$py"
}

find_port() {
    if [[ -n "${FT60_PORT:-}" ]]; then
        echo "$FT60_PORT"
        return
    fi
    local ports=(/dev/cu.usbserial-*)
    if [[ ! -e "${ports[0]}" ]]; then
        echo "Cable not found. Check that the USB end is plugged in." >&2
        exit 1
    fi
    if [[ ${#ports[@]} -gt 1 ]]; then
        echo "Several serial ports found: ${ports[*]}" >&2
        echo "Choose one with: FT60_PORT=/dev/cu.usbserial-XXXX $0" >&2
        exit 1
    fi
    echo "${ports[0]}"
}

PY="$(python_for_chirp)"
tool() {
    local name="$1"
    shift
    "$PY" "$ROOT/tools/$name.py" "$@"
}

pause() {
    read -r -p "$1 Press Enter when ready (Ctrl-C to stop): " _
}

clone_screen_prompt() {
    echo
    echo "Get the radio to the CLONE screen:"
    echo "  1. Turn the radio off."
    echo "  2. Hold MONI while turning it on, then let go."
    echo "  3. Turn the dial to F8 CLONE and press F/W briefly."
}

# Starts listening first, so the operator can press PTT with no time pressure.
read_radio() {
    local out="$1"
    clone_screen_prompt
    echo "  4. Do not press MONI. PTT sends; MONI puts the radio in receive."
    pause "Radio on the CLONE screen?"
    tool download_image "$PORT" "$out"
}

write_radio() {
    local image="$1"
    clone_screen_prompt
    echo "  4. Press MONI once so --RX-- shows."
    pause "Radio showing --RX--?"
    tool upload_image "$PORT" "$image"
}
