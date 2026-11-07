# FT-60R Programming: EVARC Channels

Everything needed to back up, change, program and verify a Yaesu FT-60R from this Mac, using an RT Systems USB-57B cable and CHIRP.

## Quick reference

Run these from this folder. Each script tells you what to press on the radio.

| Task | Command | Changes the radio? |
|---|---|---|
| Install CHIRP (once) | `./setup.sh` | No |
| Get the latest club channel sheet | `./fetch-channel-sheet.sh` | No |
| Back up the radio | `./backup.sh` | No |
| Check the radio against the channel file | `./verify.sh` | No |
| Program the radio from the channel file | `./program.sh` | Yes |
| Program, and empty any memory not in the file | `./program.sh --prune` | Yes |
| Put a saved image back on the radio | `./restore.sh images/<file>.img` | Yes |

To change repeaters: edit `ft60r-evarc-channels.csv`, then run `./program.sh`. It backs up the radio first and checks the result afterwards.

## What you need

- A Mac with this folder.
- [uv](https://docs.astral.sh/uv/getting-started/installation/), the Python tool that installs CHIRP. Check with `uv --version`.
- Git, needed to fetch CHIRP. Check with `git --version`.
- The RT Systems USB-57B cable. macOS needs no driver for it.
- An internet connection for the first `./setup.sh`.

`./setup.sh` installs the command-line CHIRP, pinned to the version this project was tested with. It comes from the official source at [github.com/kk7ds/chirp](https://github.com/kk7ds/chirp). Do not `pip install chirp`: the PyPI package of that name is an unrelated project.

To confirm the cable is seen, plug in the USB end and run `ls /dev/cu.usbserial-*`. This cable shows as `/dev/cu.usbserial-RTB6XVXV`. The radio does not need to be on for this.

## Files

```
README.md                            This file
ft60r-evarc-channels.csv             THE CHANNEL LIST. Edit this to change the radio.

setup.sh      Install CHIRP
fetch-channel-sheet.sh   Download the latest club channel sheet
backup.sh     Save the radio to images/
verify.sh     Read the radio and compare it with the CSV
program.sh    Back up, write the CSV to the radio, read back, verify
restore.sh    Write a saved image back to the radio
common.sh     Shared by the scripts. Do not run it directly.

tools/        Python used by the scripts
images/       Radio images. Scripts add dated files and never overwrite one.
```

**Not in Git:** the club's PDF and all radio images except one are ignored, so they are never published. They exist only on this Mac, so a fresh clone won't have them, and your backups need their own copy somewhere safe.

- `images/ft60r-readback-2026-11-06.img`: the radio after programming, read back and verified. This is the one image in the repo.
- `images/ft60r-backup-2026-11-06.img`: the radio before any programming. Local only.

Scripts name new images like this:

- `backup-<date>-<time>.img`: a backup. `backup.sh mylabel` adds your label to the name.
- `backup-<date>-<time>-before-programming.img`: the automatic backup from `program.sh`.
- `new-<date>-<time>.img`: what `program.sh` wrote to the radio.
- `readback-<date>-<time>.img`: what the radio contained when read back.

An image holds the radio's whole memory: every channel and every setting.

## Get the latest channel sheet

```
./fetch-channel-sheet.sh
```

The club publishes the sheet at [evarc.net/repeaters](https://evarc.net/repeaters/), under the **Radio Operations** menu as **Standard Channel Assignments**. The PDF's address has its date in it and changes with each update, so the script finds the current link by that label.

It saves the PDF here under the club's file name, or tells you that you already have that version. It never replaces an existing file. If the club renames the menu item, the script stops and says so; update `LINK_TEXT` at the top of the script.

A new sheet doesn't update anything by itself. Compare it with `ft60r-evarc-channels.csv`, edit the CSV, then run `./program.sh`.

## Radio keys

The FT-60R has one special mode for cloning.

**To reach the CLONE screen:**

1. Connect the cable to the MIC/SP jack and push it in firmly.
2. Turn the radio off.
3. Hold **MONI** while turning the radio on, then let go.
4. Turn the dial to **F8 CLONE**.
5. Press **F/W** briefly.

**Then:**

- **PTT** sends from the radio to the computer. Used for backup, verify and read-back.
- **MONI** makes the radio wait to receive, showing `--RX--`. Used only for writing to the radio.

If you need to send and the radio shows `RX`, you pressed MONI. Turn it off and start again.

The order differs by direction, and the scripts prompt you for each:

- **Radio to computer:** the script starts listening first, then you hold PTT for one second. You have 3 minutes.
- **Computer to radio:** you get `--RX--` showing first, then press Enter in the script.

Turn the radio off and on afterwards to leave clone mode. Don't touch the radio or cable during a transfer.

## Back up the radio

```
./backup.sh
./backup.sh before-field-day     # optional label in the file name
```

Follow the prompts. This only reads from the radio.

## Change the channels

Edit `ft60r-evarc-channels.csv` in a plain text editor. A text editor is safer than a spreadsheet app, which may reformat values. Keep the header line and all the columns.

| Column | Meaning |
|---|---|
| `Location` | Memory number, 1 to 1000 |
| `Name` | Up to 6 characters. **UPPERCASE letters and digits only.** See below. |
| `Frequency` | Receive frequency in MHz |
| `Duplex` | `+` or `-` for a repeater, empty for simplex, `off` to block transmit, `split` for an unusual pair |
| `Offset` | Offset in MHz, usually `0.600000` on 2 m and `5.000000` on 70 cm. With `split`, this is the transmit frequency. |
| `Tone` | `Tone` sends a tone but hears everyone. `TSQL` also requires the tone to hear a station. Empty means no tone. |
| `rToneFreq` | The tone in Hz, such as `100.0`. Must be a standard CTCSS tone. |
| `Mode` | `FM`, `NFM` (narrow) or `AM` |
| `TStep` | Tuning step in kHz. Leave at `5.00`. |
| `Skip` | Empty scans normally, `S` skips in scan, `P` makes it a priority channel |
| `Power` | `5.0W` (High), `2.0W` (Mid) or `0.5W` (Low) |
| `Comment` | Your notes. Not stored on the radio. |

Leave the other columns (`cToneFreq`, `DtcsCode`, `DtcsPolarity`, `RxDtcsCode`, `CrossMode`) as they are.

**Common edits:**

- **Change a repeater:** edit its row.
- **Add a channel:** copy a similar row and give it an unused `Location`.
- **Remove a channel:** delete its row, then run `./program.sh --prune`. Without `--prune`, the old memory stays on the radio.

`--prune` empties **every** memory with no row in the CSV, so check first that nothing you want is outside the file. `./verify.sh` lists such memories.

**Names must be uppercase.** The radio's character set has no ordinary lowercase letters, and CHIRP silently drops them or replaces them with look-alike symbols: `horth2` became `o2` in testing. Names over 6 characters are cut off. `program.sh` catches both and stops before writing.

Blank values in `Tone` matter: a repeater row with an empty `Tone` will not open that repeater if it requires one. Most repeaters on this list do.

## Program the radio

```
./program.sh
```

It runs four steps and stops if any one fails:

1. **Back up:** reads the radio to `images/`.
2. **Build:** applies the CSV to that backup, so memories not in the CSV and all radio settings are kept. It lists which memories will change, checks the result, and waits for you to type `yes`. Nothing has been written up to this point.
3. **Write:** sends the new image to the radio.
4. **Read back:** reads the radio again and compares it with what was sent, byte for byte.

Success ends with `VERIFY OK (byte-for-byte match)`. Then turn the radio off and on and try it on the air.

To use a different channel file:

```
CSV=my-other-channels.csv ./program.sh
```

## Verify the radio

```
./verify.sh
./verify.sh my-other-channels.csv
```

This reads the radio and checks each channel's frequency, name, duplex, offset, tone, tone frequency and mode against the CSV. It also checks the image checksum and lists memories that aren't in the CSV. It does not compare `Power`, `Skip` or `TStep`.

`VERIFY OK` means the radio matches. `VERIFY FAILED` lists each channel that doesn't.

A passing check confirms what is stored in the radio. It doesn't prove a repeater is still on that frequency and tone, so test on the air too.

## Restore a saved image

```
./restore.sh images/ft60r-readback-2026-11-06.img     # the verified EVARC programming
./restore.sh images/ft60r-backup-2026-11-06.img       # the radio before any programming (local only)
```

This replaces **everything** on the radio, settings included. It asks you to type `yes`, writes the image, then reads back to confirm. Success ends with `RESTORE OK`.

This is also the fix if a write is interrupted and the radio's memory looks scrambled.

## Test on the air

After programming, unplug the cable and:

1. Press **V/M** for memory mode and turn the dial through some channels. Check the names.
2. Try a repeater you can reach.
3. Check channel 62 (`RMNP`) won't transmit when you press PTT. The radio should refuse, possibly showing `ERROR`.

If you hear a repeater but can't open it, check its tone and frequency. The club sheet dates from June 2023 and repeaters do change.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `CHIRP is not installed` | Run `./setup.sh`. |
| `Cable not found` | Plug in the USB end, or try another port. |
| `Several serial ports found` | Run with the port named: `FT60_PORT=/dev/cu.usbserial-XXXX ./backup.sh` |
| `timed out: the radio never sent anything` | Check the plug is fully seated in the MIC/SP jack, get back to the CLONE screen, and hold PTT once the script says it's listening. |
| Radio shows `RX` when you meant to send | MONI was pressed. Turn the radio off and start over. |
| `No response from radio` or `UPLOAD FAILED` on write | Radio wasn't showing `--RX--`, or the plug is loose. Get back to `--RX--` and retry. The backup is already saved. |
| `DOWNLOAD FAILED: Checksum Failed` | The transfer or the radio's memory is bad. Reseat the cable and retry. If it repeats, use `./restore.sh`. |
| `ERROR` on the radio at the end of a send | Turn it off and on. Go by what the script reports: if it saved the image, the data arrived complete. This appeared once in 2026 and was probably caused by a longer serial timeout that has since been removed. |
| `VERIFY FAILED` during `program.sh` step 2 | The CSV has a problem. The message names the channel. The radio hasn't been changed. |
| `VERIFY FAILED` after writing | The write didn't land as intended. Run `./program.sh` again. |
| A script stops at a prompt | Press Ctrl-C to quit. Quitting at any prompt is safe, as no transfer is running. |

Output goes to the screen. CHIRP's own log, if any, is at `~/.chirp/debug.log`.

## If the scripts ever stop working

The desktop CHIRP app does the same job. Download it in a browser from [chirpmyradio.com](https://chirpmyradio.com), choose Yaesu FT-60 when downloading from the radio, and then use its import option to load `ft60r-evarc-channels.csv` into memories 1 to 63. Download from the radio before importing, and save that image first. The app also gives you the on-screen instructions for the radio's keys.

To move to a newer CHIRP, change `CHIRP_COMMIT` in `setup.sh` and run `./setup.sh`. Run `./verify.sh` afterwards, which is safe because it doesn't write to the radio.

## Notes on the channel data

The CSV comes from the [Estes Valley Amateur Radio Club](https://evarc.net/repeaters/) sheet dated 2023-06-04 (`Channel-Assignments-2023-06-04.pdf`) and uses memories 1 to 63, matching the sheet's channel numbers. Channel 60 is blank on the sheet.

**Choices made during programming:**

- All tones are transmit-only (`Tone`), including on simplex. The sheet's 67.0 Hz on simplex and packet channels would otherwise stop you hearing stations that don't send it.
- Channel 62 (`RMNP`) has transmit disabled, as the sheet says monitor only. It's set to narrow FM on the assumption that it's a narrowband federal channel.
- All channels are on high power (5 W).

**Differences from the sheet:**

- Channel 5 is `LOVLD2`. The sheet has `L0VLD2` with a zero.
- Channels 19 and 20 are `SKYWNA` (103.5 Hz, regular mode) and `SKYWNB` (91.5 Hz, severe weather mode). The sheet calls both `SKYWN`.

**Kept as printed, on purpose:**

- Channel 54 stays at 448.8 / 443.8 with no tone, even though the sheet labels it a reverse of the Estes UHF repeater, which uses 449.8 / 444.8.
- The names on channels 53, 54, 55 and 57 stay as printed, so 54 and 57 are both `EVRVC7`.

If the club issues a new sheet, compare it with the CSV row by row, and keep these choices in mind.
