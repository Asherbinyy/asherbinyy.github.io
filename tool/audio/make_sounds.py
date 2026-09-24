"""Synthesises the climb's reward sounds.

Every sample the game plays is generated here rather than sourced, so there is
no licence to carry for any of them and the whole set stays a few tens of
kilobytes. Run from the repository root:

    python3 tool/audio/make_sounds.py

It only writes the files it owns; the original five are untouched.
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



def glide(frames, f0, f1, amp, length, start=0.0):
    """A sine whose pitch slides from f0 to f1 over `length` seconds."""
    begin = int(start * RATE)
    phase = 0.0
    count = int(length * RATE)
    for n in range(count):
        i = begin + n
        if i >= len(frames):
            break
        t = n / count
        freq = f0 + (f1 - f0) * t
        phase += 2 * math.pi * freq / RATE
        env = math.sin(math.pi * t) ** 1.5
        frames[i] += amp * env * math.sin(phase)


def noise(frames, amp, length, start=0.0, seed=7):
    """Soft filtered noise with a swell, for wind and sand."""
    begin = int(start * RATE)
    count = int(length * RATE)
    state = seed
    last = 0.0
    for n in range(count):
        i = begin + n
        if i >= len(frames):
            break
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        white = state / 0x7FFFFFFF * 2 - 1
        last = last * 0.96 + white * 0.04
        env = math.sin(math.pi * n / count)
        frames[i] += amp * env * last * 6


def ankh():
    """An extra life: a bright major chord struck twice, rising."""
    frames = [0.0] * int(RATE * 1.1)
    for index, freq in enumerate((659.25, 830.61, 987.77, 1318.51)):
        tone(frames, freq, 0.42, 4.2, start=index * 0.06, harmonic=0.25)
    return frames


def eye():
    """The floor slows: a long tone that bends down, time stretching."""
    frames = [0.0] * int(RATE * 1.2)
    glide(frames, 880, 330, 0.5, 1.1)
    glide(frames, 1320, 495, 0.2, 1.1, start=0.02)
    return frames


def feather():
    """Lightness: three quick rising notes, airy."""
    frames = [0.0] * int(RATE * 0.7)
    for index, freq in enumerate((783.99, 1046.50, 1567.98)):
        tone(frames, freq, 0.38, 9.0, start=index * 0.07, harmonic=0.1)
    noise(frames, 0.05, 0.4)
    return frames


def life():
    """A life spent: a low gong with a slow tail."""
    frames = [0.0] * int(RATE * 1.3)
    tone(frames, 110.0, 0.6, 2.6, harmonic=0.6)
    tone(frames, 164.81, 0.3, 3.5, start=0.01)
    return frames


def win():
    """The summit: a fanfare up an octave, held."""
    frames = [0.0] * int(RATE * 2.4)
    for index, freq in enumerate((392.00, 523.25, 659.25, 783.99, 1046.50)):
        tone(frames, freq, 0.42, 1.8, start=index * 0.13, harmonic=0.35)
    return frames


def sand():
    """The sands: wind across the shaft and a thin whistle riding it."""
    frames = [0.0] * int(RATE * 1.6)
    noise(frames, 0.35, 1.6)
    glide(frames, 1200, 1500, 0.08, 1.4, start=0.1)
    return frames


if __name__ == '__main__':
    write('reward', reward())
    write('record', record())
    write('level', level())
    write('ankh', ankh())
    write('eye', eye())
    write('feather', feather())
    write('life', life())
    write('win', win())
    write('sand', sand())
