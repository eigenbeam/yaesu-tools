"""Check an FT-60 image against a CSV, and optionally against another image.

usage: verify_image.py <image.img> <channels.csv> [expected.img]

Exits non-zero if anything does not match.
"""
import csv
import sys

from ft60_link import load_image, used_memories

from chirp import errors

image, csv_path = sys.argv[1:3]
expected = sys.argv[3] if len(sys.argv) > 3 else None
radio = load_image(image)
problems = []

try:
    radio.check_checksums()
except errors.RadioError as e:
    problems.append(f'checksum: {e}')

with open(csv_path, newline='') as f:
    rows = {int(r['Location']): r for r in csv.DictReader(f)}

for number, row in sorted(rows.items()):
    mem = radio.get_memory(number)
    if mem.empty:
        problems.append(f'channel {number}: empty on the radio')
        continue
    duplex = row['Duplex']
    actual = (mem.freq, mem.name.strip(), mem.duplex, mem.tmode, mem.mode)
    wanted = (round(float(row['Frequency']) * 1e6), row['Name'], duplex, row['Tone'], row['Mode'])
    if actual != wanted:
        problems.append(f'channel {number}: radio has {actual}, CSV has {wanted}')
    if duplex in ('+', '-', 'split') and mem.offset != round(float(row['Offset']) * 1e6):
        problems.append(f'channel {number}: offset {mem.offset} differs from CSV')
    if row['Tone'] and mem.rtone != float(row['rToneFreq']):
        problems.append(f'channel {number}: tone {mem.rtone} differs from CSV')

if expected:
    wanted_bytes = load_image(expected).get_mmap().get_packed()
    if radio.get_mmap().get_packed() != wanted_bytes:
        problems.append(f'image bytes differ from {expected}')

extra = [n for n in used_memories(radio) if n not in rows]
print(f'Checked {len(rows)} channels from {csv_path}')
print(f'Memories in use that are not in the CSV: {extra or "none"}')
if problems:
    print('VERIFY FAILED:')
    for problem in problems:
        print(f'  {problem}')
    sys.exit(1)
print('VERIFY OK' + (' (byte-for-byte match)' if expected else ''))
