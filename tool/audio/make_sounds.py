"""Synthesises the climb's reward sounds.

Every sample the game plays is generated here rather than sourced, so there is
no licence to carry for any of them and the whole set stays a few tens of
kilobytes. Run from the repository root:

    python3 tool/audio/make_sounds.py

It only writes the three files it owns; the original five are untouched.
"""

import math
import struct
import wave

RATE = 44100


def tone(frames, freq, amp, decay, start=0.0, harmonic=0.0):
    """Adds a plucked sine with an exponential tail into `frames`."""
    begin = int(start * RATE)
    for i in range(begin, len(frames)):
        t = (i - begin) / RATE
        env = math.exp(-t * decay)
        if env < 0.0005:
            break
        v = math.sin(2 * math.pi * freq * t)
        if harmonic:
            v += harmonic * math.sin(4 * math.pi * freq * t)
        frames[i] += amp * env * v


def write(name, frames):
    peak = max(1e-9, max(abs(f) for f in frames))
    scale = 0.89 / peak
    data = b''.join(
        struct.pack('<h', int(max(-1.0, min(1.0, f * scale)) * 32767))
        for f in frames
    )
    with wave.open('assets/audio/%s.wav' % name, 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data)
    print(name, len(data) // 2, 'frames')


def reward():
    """Every hundred metres: a rising fourth on a struck bar."""
    frames = [0.0] * int(RATE * 0.9)
    for index, freq in enumerate((523.25, 698.46, 1046.50)):
        tone(frames, freq, 0.5, 5.5, start=index * 0.085, harmonic=0.22)
    return frames


def record():
    """A run that beat the best: the same figure, lower and longer."""
    frames = [0.0] * int(RATE * 1.4)
    for index, freq in enumerate((392.00, 523.25, 659.25, 783.99)):
        tone(frames, freq, 0.45, 3.2, start=index * 0.11, harmonic=0.3)
    return frames


def level():
    """A band passed: one low strike, felt more than heard."""
    frames = [0.0] * int(RATE * 0.5)
    tone(frames, 146.83, 0.6, 9.0, harmonic=0.5)
    tone(frames, 220.00, 0.25, 12.0, start=0.02)
    return frames



if __name__ == '__main__':
    write('reward', reward())
    write('record', record())
    write('level', level())
