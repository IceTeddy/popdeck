#!/usr/bin/env python3
"""Stage a locally installed Apple time-wheel sound for Dev auditioning only."""
from pathlib import Path
import struct
import sys

app = Path(sys.argv[1])
roots = sorted(Path('/Library/Developer/CoreSimulator/Volumes').glob(
    '*/Library/Developer/CoreSimulator/Profiles/Runtimes/*.simruntime/Contents/Resources/RuntimeRoot/System/Library/Audio/UISounds/nano/TimerWheelMinutesDetent_Haptic.caf'))
if roots:
    # The original peak is only ~0.047 full scale. Amplify the PCM rather than
    # exceeding AVAudioPlayer's 0...1 volume range; keep the source untouched.
    data = bytearray(roots[0].read_bytes())
    if data[:4] != b'caff':
        raise ValueError('Expected a CAF time-wheel sample')
    offset = 8
    pcm_range = None
    supported = False
    while offset + 12 <= len(data):
        kind, length = struct.unpack_from('>4sq', data, offset)
        start = offset + 12
        if length < 0 or start + length > len(data):
            raise ValueError('Invalid CAF chunk length')
        if kind == b'desc':
            _, codec, flags, packet_bytes, packet_frames, channels, bits = struct.unpack_from('>d4sIIIII', data, start)
            supported = (codec, flags, packet_bytes, packet_frames, channels, bits) == (b'lpcm', 2, 2, 1, 1, 16)
        elif kind == b'data':
            pcm_range = (start + 4, start + length)
        offset = start + length
    if not supported or pcm_range is None:
        raise ValueError('Expected mono little-endian signed PCM16')
    start, end = pcm_range
    samples = struct.unpack_from('<' + 'h' * ((end - start) // 2), data, start)
    peak = max(abs(sample) for sample in samples)
    gain = min(10.0, 0.95 * 32767 / peak) if peak else 1.0
    amplified = [round(sample * gain) for sample in samples]
    struct.pack_into('<' + 'h' * len(amplified), data, start, *amplified)
    (app / 'Contents/Resources/hover-apple-picker.caf').write_bytes(data)
    print(f'Staged Apple time-wheel sound for Dev with {gain:.2f}x PCM gain (no clipping).')
