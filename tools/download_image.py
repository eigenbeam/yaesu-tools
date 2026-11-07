"""Download an FT-60 image, waiting for PTT for up to `seconds`.

usage: download_image.py <port> <output.img> [seconds]
"""
import os
import sys
import time

from ft60_link import open_radio, used_memories

from chirp import errors

port, out_img = sys.argv[1:3]
seconds = int(sys.argv[3]) if len(sys.argv) > 3 else 180
if os.path.exists(out_img):
    sys.exit(f'refusing to overwrite {out_img}')

radio = open_radio(port)
print(f'Listening for {seconds} seconds. Hold PTT on the radio for one second now.', flush=True)
deadline = time.time() + seconds
while True:
    try:
        radio.sync_in()
        break
    except errors.RadioNoResponse:
        if time.time() > deadline:
            sys.exit('timed out: the radio never sent anything')
    except errors.RadioError as e:
        # stray bytes before the image (e.g. power cycling) are not a transfer
        if 'invalid response' not in str(e) or time.time() > deadline:
            sys.exit(f'DOWNLOAD FAILED: {e}')
        radio.pipe.reset_input_buffer()
radio.save_mmap(out_img)
print(f'Saved {out_img} ({len(used_memories(radio))} memories in use)', flush=True)
