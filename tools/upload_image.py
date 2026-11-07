"""Upload an FT-60 image. The radio must already show --RX--.

usage: upload_image.py <port> <image.img>
"""
import sys

from ft60_link import open_radio

from chirp import errors

port, image = sys.argv[1:3]
radio = open_radio(port)
radio.load_mmap(image)
print('Uploading. Do not touch the radio or cable...', flush=True)
try:
    radio.sync_out()
except errors.RadioError as e:
    sys.exit(f'UPLOAD FAILED: {e}')
print('Upload complete', flush=True)
