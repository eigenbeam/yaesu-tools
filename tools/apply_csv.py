"""Apply a CHIRP CSV to an FT-60 image, leaving other memories and all settings alone.

usage: apply_csv.py <channels.csv> <input.img> <output.img> [--prune]

--prune also empties every memory that has no row in the CSV.
"""
import sys

from ft60_link import load_image, used_memories

from chirp import chirp_common, import_logic
from chirp.drivers import generic_csv

args = [a for a in sys.argv[1:] if a != '--prune']
prune = '--prune' in sys.argv
csv_path, in_img, out_img = args
src = generic_csv.CSVRadio(csv_path)
radio = load_image(in_img)
before = {n: str(radio.get_memory(n)) for n in range(1, 1001)}
features = src.get_features()
in_csv = set()
for number in range(*features.memory_bounds):
    mem = src.get_memory(number)
    if mem.empty:
        continue
    try:
        new = import_logic.import_mem(radio, features, mem, {'number': mem.number})
    except Exception as e:
        sys.exit(f'channel {mem.number}: {e}')
    errors = radio.validate_memory(new)
    if errors:
        sys.exit(f'channel {mem.number}: {errors}')
    radio.set_memory(new)
    in_csv.add(mem.number)

others = [n for n in used_memories(radio) if n not in in_csv]
if prune:
    for number in others:
        radio.set_memory(chirp_common.Memory(number, True))
elif others:
    print(f'Kept memories not in the CSV: {others}')

radio.update_checksums()
radio.save_mmap(out_img)
changed = [n for n in range(1, 1001) if str(radio.get_memory(n)) != before[n]]
print(f'Wrote {len(in_csv)} channels to {out_img}')
print(f'Memories that differ from the input image: {changed or "none"}')
