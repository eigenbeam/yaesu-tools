"""Shared helpers for the FT-60 tools."""
import builtins
import os
import warnings

# Without this, CHIRP redirects all output to ~/.chirp/debug.log when stdin is not a terminal.
os.environ.setdefault('CHIRP_TESTENV', '1')

# CHIRP's error messages call _(), which only its GUI normally installs.
builtins._ = lambda text: text

import serial

from chirp import directory
from chirp.drivers import ft60

directory.import_drivers()
warnings.simplefilter('ignore', DeprecationWarning)


def open_radio(port):
    pipe = serial.Serial(port=port, baudrate=ft60.FT60Radio.BAUD_RATE,
                         rtscts=ft60.FT60Radio.HARDWARE_FLOW, timeout=0.25)
    pipe.rts = ft60.FT60Radio.WANTS_RTS
    pipe.dtr = ft60.FT60Radio.WANTS_DTR
    return ft60.FT60Radio(pipe)


def load_image(path):
    radio = ft60.FT60Radio(None)
    radio.load_mmap(path)
    return radio


def used_memories(radio):
    return [n for n in range(1, 1001) if not radio.get_memory(n).empty]
