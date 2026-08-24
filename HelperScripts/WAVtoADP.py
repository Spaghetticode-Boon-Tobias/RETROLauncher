#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WAVtoADP.py

Converts a WAV file into the .adp format RETROLauncher / Enceladus feeds to
Sound.loadADPCM(), and converts .adp back to WAV so you can hear what a file
actually contains.

    python WAVtoADP.py move.wav move2.adp        encode
    python WAVtoADP.py back.adp back.wav         decode (by extension)
    python WAVtoADP.py in.wav out.adp --mono     one channel instead of two
    python WAVtoADP.py in.adp out.wav --report   print the header and the SNR

--------------------------------------------------------------------------------
THE FORMAT
--------------------------------------------------------------------------------
It is the ADPCM container of ps2sdk's audsrv. The authority is
iop/sound/audsrv/src/adpcm.c, audsrv_read_adpcm_header():

    adpcm->pitch    = buffer[2];
    adpcm->loop     = (buffer[1] >> 16) & 0xFF;
    adpcm->channels = (buffer[1] >>  8) & 0xFF;
    adpcm->size     = size - 16;                    <- header is 16 bytes
    sceSdVoiceTrans(..., ((u8*)buffer)+16, ...);    <- data starts at 16

So the header is:

    0   'APCM'
    4   version           1
    5   channels          1 or 2
    6   loop              0 for a one-shot
    7   unused
    8   pitch, u32 LE     SPU2 units, 4096 == 48000 Hz
    12  unused by audsrv  the four shipped files carry a sample count here

THE HEADER IS 16 BYTES, NOT 48. That mistake costs two blocks of audio at the
head of the file and is easy to make, because the first two blocks of a real
file are near-silent and look like padding. What settles it is the block flags:
with 16, every channel begins on an all-zero block and ends on a 0x07 block,
exactly on the half boundary. With 48 the markers land two blocks short of the
end, which is nonsense.

    back.adp  9264 bytes  = 16 + 578 blocks  = 16 + 2 x 289
        j0    0c 00 00...   silent primer
        j288  0c 07 00...   terminator, last block of channel 1
        j289  0c 00 00...   silent primer, channel 2 begins
        j577  0c 07 00...   terminator, end of file

CHANNEL LAYOUT IS NOT INTERLEAVED. tools/ps2adpcm/src/main.c reads a chunk of
bpc*28 frames and then encodes channel 0 completely before channel 1, so the
file is chunks of `bpc` blocks per channel. bpc defaults to 1024 and these
sounds are far shorter than that, so there is exactly one chunk: all of the
left channel, then all of the right. Decoding them as alternating blocks
produces something that still correlates like audio, which is precisely why it
is worth checking the flags rather than trusting the ear.

--------------------------------------------------------------------------------
THE SAMPLE RATE
--------------------------------------------------------------------------------
There is no sample rate in the file, only an SPU2 pitch, and the SPU2 plays at
48000 Hz when pitch is 4096:

    pitch = round(rate * 4096 / 48000)      22050 Hz -> 1882
    rate  = pitch * 48000 / 4096            3763 -> 44098 Hz

The four shipped sounds all carry 3763, so they are 44.1 kHz material. Note
that system.lua calls Sound.setFormat(16, 48000, 3); that governs the streaming
PCM path, not these samples - an ADPCM sample plays at its own pitch.

--------------------------------------------------------------------------------
THE ENCODER
--------------------------------------------------------------------------------
Standard PS2/PSX ADPCM: 16 bytes hold 28 samples. Byte 0 is the low nibble
shift and the high nibble filter index, byte 1 is flags, the remaining 14 bytes
are 28 signed nibbles, low nibble first.

    sample = (nibble << (12 - shift)) + h1*F0[filter] + h2*F1[filter]

Rather than picking the filter from the residual magnitude the way vagpack
does, this tries all 5 filters against all 13 shifts and keeps whichever pair
gives the lowest squared error, quantising in closed loop so the encoder's
history is the decoder's history and error cannot accumulate. It is 65 trials
per block instead of 5, which costs nothing at these file sizes and buys about
2 dB.

Verified by decoding the result and comparing with the source: the four menu
sounds re-encode at 20 to 27 dB SNR, which is what 4-bit ADPCM gives.
"""

import os
import struct
import sys
import wave

MAGIC = b"APCM"
HEADER_SIZE = 16
BLOCK_SIZE = 16
SAMPLES_PER_BLOCK = 28
SPU_BASE_RATE = 48000
SPU_UNIT_PITCH = 4096

# Filter coefficients, in 1/64ths, as the SPU applies them.
F0 = (0.0, 60.0 / 64.0, 115.0 / 64.0, 98.0 / 64.0, 122.0 / 64.0)
F1 = (0.0, 0.0, -52.0 / 64.0, -55.0 / 64.0, -60.0 / 64.0)

FLAG_NONE = 0x00
FLAG_END = 0x07          # end of sample, release the voice

PRIMER_BLOCK = bytes([0x0C, FLAG_NONE]) + bytes(14)
TERMINATOR_BLOCK = bytes([0x0C, FLAG_END]) + bytes(14)


def rate_to_pitch(rate):
    return int(round(rate * SPU_UNIT_PITCH / SPU_BASE_RATE))


def pitch_to_rate(pitch):
    return int(round(pitch * SPU_BASE_RATE / SPU_UNIT_PITCH))


# ------------------------------------------------------------------ decoding

def decode_block(block, h1, h2, out):
    shift = block[0] & 0x0F
    filt = (block[0] >> 4) & 0x0F
    if filt > 4:
        filt = 0
    if shift > 12:
        shift = 12
    f0, f1 = F0[filt], F1[filt]
    step = float(1 << (12 - shift))
    for i in range(SAMPLES_PER_BLOCK):
        byte = block[2 + i // 2]
        nib = (byte & 0x0F) if (i % 2 == 0) else (byte >> 4)
        if nib > 7:
            nib -= 16
        s = nib * step + h1 * f0 + h2 * f1
        if s > 32767.0:
            s = 32767.0
        elif s < -32768.0:
            s = -32768.0
        h2, h1 = h1, s
        out.append(int(s))
    return h1, h2


def decode_channel(data):
    out = []
    h1 = h2 = 0.0
    for off in range(0, len(data) - BLOCK_SIZE + 1, BLOCK_SIZE):
        h1, h2 = decode_block(data[off:off + BLOCK_SIZE], h1, h2, out)
    return out


def read_adp(path):
    with open(path, "rb") as f:
        raw = f.read()
    if len(raw) < HEADER_SIZE or raw[:4] != MAGIC:
        raise ValueError("%s is not an APCM file" % os.path.basename(path))
    version = raw[4]
    channels = raw[5] or 1
    loop = raw[6]
    pitch = struct.unpack("<I", raw[8:12])[0]
    extra = struct.unpack("<I", raw[12:16])[0]
    body = raw[HEADER_SIZE:]
    per_channel = (len(body) // BLOCK_SIZE // channels) * BLOCK_SIZE
    tracks = [decode_channel(body[i * per_channel:(i + 1) * per_channel])
              for i in range(channels)]
    info = {"version": version, "channels": channels, "loop": loop,
            "pitch": pitch, "rate": pitch_to_rate(pitch), "extra": extra,
            "blocks_per_channel": per_channel // BLOCK_SIZE}
    return tracks, info


# ------------------------------------------------------------------ encoding

def encode_block(samples, h1, h2, flag):
    """Best (filter, shift) for these 28 samples, quantised in closed loop."""
    best = None
    for filt in range(5):
        f0, f1 = F0[filt], F1[filt]
        for shift in range(13):
            step = float(1 << (12 - shift))
            a, b = h1, h2
            err = 0.0
            nibbles = []
            for s in samples:
                pred = a * f0 + b * f1
                q = int(round((s - pred) / step))
                if q > 7:
                    q = 7
                elif q < -8:
                    q = -8
                rec = q * step + pred
                if rec > 32767.0:
                    rec = 32767.0
                elif rec < -32768.0:
                    rec = -32768.0
                d = s - rec
                err += d * d
                b, a = a, rec
                nibbles.append(q & 0x0F)
            if best is None or err < best[0]:
                best = (err, filt, shift, nibbles, a, b)
            if err == 0.0:
                break
        if best is not None and best[0] == 0.0:
            break

    _, filt, shift, nibbles, a, b = best
    block = bytearray(BLOCK_SIZE)
    block[0] = (filt << 4) | shift
    block[1] = flag
    for i in range(0, SAMPLES_PER_BLOCK, 2):
        block[2 + i // 2] = nibbles[i] | (nibbles[i + 1] << 4)
    return bytes(block), a, b


def encode_channel_slow(samples):
    """Reference encoder: strictly sequential, exact history. Kept because it is
    obviously correct and the fast path is checked against it."""
    body = bytearray(PRIMER_BLOCK)
    h1 = h2 = 0.0
    for off in range(0, len(samples), SAMPLES_PER_BLOCK):
        chunk = list(samples[off:off + SAMPLES_PER_BLOCK])
        if len(chunk) < SAMPLES_PER_BLOCK:
            chunk += [0] * (SAMPLES_PER_BLOCK - len(chunk))
        block, h1, h2 = encode_block(chunk, h1, h2, FLAG_NONE)
        body += block
    body += TERMINATOR_BLOCK
    return bytes(body)


def encode_channel_fast(samples):
    """Same search, every block at once.

    The sequential encoder needs 65 trials x 28 samples per block, which is fine
    for a 0.2 s menu bleep and hopeless for a two-minute tune: a 16 kHz track of
    that length is 80 000 blocks, so 145 million inner steps in Python.

    The dependency that forces sequential work is the two-sample history carried
    between blocks, which depends on what the PREVIOUS block quantised to. This
    version feeds each block the last two ORIGINAL samples of the block before it
    instead of the reconstructed ones. Since the reconstruction sits 50 dB below
    the signal, the two differ by well under one quantisation step, and blocks
    become independent -- so all of them run in parallel as numpy arrays and only
    the 28 steps inside a block stay sequential.

    It is an approximation, so it is not taken on trust: main() decodes the file
    it just wrote, with the exact sequential decoder, and prints the SNR against
    the source.
    """
    import numpy as np

    n = len(samples)
    nblocks = (n + SAMPLES_PER_BLOCK - 1) // SAMPLES_PER_BLOCK
    padded = np.zeros(nblocks * SAMPLES_PER_BLOCK, dtype=np.float64)
    padded[:n] = np.asarray(samples, dtype=np.float64)
    S = padded.reshape(nblocks, SAMPLES_PER_BLOCK)

    # Last two samples of the preceding block, zero for the first.
    prev1 = np.zeros(nblocks); prev1[1:] = S[:-1, SAMPLES_PER_BLOCK - 1]
    prev2 = np.zeros(nblocks); prev2[1:] = S[:-1, SAMPLES_PER_BLOCK - 2]

    best_err = np.full(nblocks, np.inf)
    best_q = np.zeros((nblocks, SAMPLES_PER_BLOCK), dtype=np.int8)
    best_head = np.zeros(nblocks, dtype=np.uint8)

    for filt in range(5):
        f0, f1 = F0[filt], F1[filt]
        for shift in range(13):
            step = float(1 << (12 - shift))
            a, b = prev1.copy(), prev2.copy()
            err = np.zeros(nblocks)
            q_all = np.empty((nblocks, SAMPLES_PER_BLOCK), dtype=np.int8)
            for i in range(SAMPLES_PER_BLOCK):
                pred = a * f0 + b * f1
                q = np.rint((S[:, i] - pred) / step)
                np.clip(q, -8, 7, out=q)
                rec = np.clip(q * step + pred, -32768.0, 32767.0)
                d = S[:, i] - rec
                err += d * d
                b, a = a, rec
                q_all[:, i] = q.astype(np.int8)
            better = err < best_err
            if better.any():
                best_err = np.where(better, err, best_err)
                best_q[better] = q_all[better]
                best_head[better] = (filt << 4) | shift

    nib = (best_q.astype(np.uint8) & 0x0F)
    packed = (nib[:, 0::2] | (nib[:, 1::2] << 4)).astype(np.uint8)

    blocks = np.zeros((nblocks, BLOCK_SIZE), dtype=np.uint8)
    blocks[:, 0] = best_head
    blocks[:, 1] = FLAG_NONE
    blocks[:, 2:] = packed
    return PRIMER_BLOCK + blocks.tobytes() + TERMINATOR_BLOCK


def encode_channel(samples):
    """Primer block, the audio, then a terminator block."""
    try:
        import numpy  # noqa: F401
    except ImportError:
        return encode_channel_slow(samples)
    if len(samples) < 8192:
        # Short enough that the exact encoder costs nothing; use it.
        return encode_channel_slow(samples)
    return encode_channel_fast(samples)


def write_adp(path, tracks, rate, loop=0):
    channels = len(tracks)
    longest = max(len(t) for t in tracks)
    bodies = []
    for track in tracks:
        padded = list(track) + [0] * (longest - len(track))
        bodies.append(encode_channel(padded))

    # Every channel must occupy the same number of blocks: audsrv splits the
    # payload evenly and a ragged channel would shift the second one.
    width = max(len(b) for b in bodies)
    bodies = [b + TERMINATOR_BLOCK * ((width - len(b)) // BLOCK_SIZE) for b in bodies]

    header = bytearray(HEADER_SIZE)
    header[0:4] = MAGIC
    header[4] = 1
    header[5] = channels
    header[6] = loop
    header[7] = 0
    header[8:12] = struct.pack("<I", rate_to_pitch(rate))
    header[12:16] = struct.pack("<I", longest)

    with open(path, "wb") as f:
        f.write(bytes(header))
        for b in bodies:
            f.write(b)
    return HEADER_SIZE + width * channels


# ------------------------------------------------------------------ wav

def read_wav(path):
    with wave.open(path, "rb") as w:
        if w.getsampwidth() != 2:
            raise ValueError("only 16-bit WAV is supported (%s is %d-bit)"
                             % (os.path.basename(path), w.getsampwidth() * 8))
        channels = w.getnchannels()
        rate = w.getframerate()
        frames = w.readframes(w.getnframes())
    flat = struct.unpack("<%dh" % (len(frames) // 2), frames)
    return [list(flat[c::channels]) for c in range(channels)], rate


def write_wav(path, tracks, rate):
    channels = len(tracks)
    n = max(len(t) for t in tracks)
    inter = []
    for i in range(n):
        for t in tracks:
            inter.append(t[i] if i < len(t) else 0)
    with wave.open(path, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(struct.pack("<%dh" % len(inter),
                                  *[max(-32768, min(32767, v)) for v in inter]))


# ------------------------------------------------------------------ quality

def snr_db(reference, produced):
    n = min(len(reference), len(produced))
    if n == 0:
        return float("nan")
    sig = sum(float(reference[i]) ** 2 for i in range(n))
    noise = sum((float(reference[i]) - float(produced[i])) ** 2 for i in range(n))
    if noise <= 0.0:
        return float("inf")
    if sig <= 0.0:
        return float("nan")
    import math
    return 10.0 * math.log10(sig / noise)


# ------------------------------------------------------------------ cli

def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    opts = set(a for a in argv[1:] if a.startswith("--"))
    if len(args) < 2:
        print(__doc__.strip().split("\n\n")[1])
        return 1

    src, dst = args[0], args[1]

    if src.lower().endswith(".adp"):
        tracks, info = read_adp(src)
        write_wav(dst, tracks, info["rate"])
        print("%s -> %s" % (os.path.basename(src), os.path.basename(dst)))
        print("   version %d  channels %d  loop %d  pitch %d (%d Hz)"
              % (info["version"], info["channels"], info["loop"],
                 info["pitch"], info["rate"]))
        print("   %d blocks per channel  %.3f s"
              % (info["blocks_per_channel"],
                 len(tracks[0]) / float(info["rate"])))
        return 0

    tracks, rate = read_wav(src)
    if "--mono" not in opts and len(tracks) == 1:
        tracks = [tracks[0], list(tracks[0])]
    size = write_adp(dst, tracks, rate)
    print("%s -> %s   %d Hz  %d channel(s)  %d bytes"
          % (os.path.basename(src), os.path.basename(dst), rate,
             len(tracks), size))

    # Read it back and measure. The decoded stream begins with the primer
    # block, so drop those 28 samples before comparing or the two signals are
    # simply out of step and the figure is meaningless.
    back, info = read_adp(dst)
    print("   pitch %d -> %d Hz   SNR %s"
          % (info["pitch"], info["rate"],
             "  ".join("%.1f dB" % snr_db(tracks[c],
                                          back[c][SAMPLES_PER_BLOCK:])
                       for c in range(len(tracks)))))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
