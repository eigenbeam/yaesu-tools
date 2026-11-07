#!/usr/bin/env bash
# Download the latest EVARC channel sheet. The PDF's URL contains its date, so
# find it through the "Standard Channel Assignments" link on the club's site.
set -euo pipefail

SOURCE_PAGE="https://evarc.net/repeaters/"
LINK_TEXT="Standard Channel Assignments"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

page="$(curl -fsSL --max-time 30 "$SOURCE_PAGE")"
url="$(LINK_TEXT="$LINK_TEXT" perl -0777 -ne '
    while (/<a\b[^>]*\bhref="([^"]+)"[^>]*>((?:(?!<\/a>).)*)<\/a>/gis) {
        my ($href, $text) = ($1, $2);
        $text =~ s/<[^>]+>//g;
        $text =~ s/&nbsp;|\s+/ /g;
        if ($text =~ /\Q$ENV{LINK_TEXT}\E/i) { print $href; last; }
    }' <<<"$page")"

if [[ -z "$url" ]]; then
    echo "No \"$LINK_TEXT\" link found on $SOURCE_PAGE." >&2
    echo "The site may have changed. Look under the Radio Operations menu." >&2
    exit 1
fi
if [[ ! "$url" =~ ^https://(www\.)?evarc\.net/[A-Za-z0-9._/-]+\.pdf$ ]]; then
    echo "Expected a PDF on evarc.net, but the link is: $url" >&2
    exit 1
fi

name="$(basename "$url")"
dest="$ROOT/$name"
echo "Latest sheet: $url"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
curl -fsSL --max-time 60 -o "$tmp" "$url"
if [[ "$(head -c 5 "$tmp")" != "%PDF-" ]]; then
    echo "The download is not a PDF." >&2
    exit 1
fi

if [[ -e "$dest" ]]; then
    if cmp -s "$tmp" "$dest"; then
        echo "You already have this version: $name"
        exit 0
    fi
    echo "$name exists here with different contents. Leaving it alone." >&2
    exit 1
fi
mv "$tmp" "$dest"
chmod 644 "$dest"
echo "Saved new sheet: $name"
echo "Compare it with ft60r-evarc-channels.csv, update the CSV, then run ./program.sh."
