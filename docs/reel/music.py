# Synthesises the reel soundtrack: 14 bars of upbeat electro-pop, fitted to a given length.
#   python3 music.py <seconds> <out.wav>
# Needs numpy only.
import sys
import wave

import numpy as np

SR = 44100
DUR = float(sys.argv[1])
OUT = sys.argv[2]
BARS = 14
BEAT = DUR / (BARS * 4)  # tempo is chosen so the bars fill the video exactly
N = int(SR * DUR)
t_all = np.arange(N) / SR
rng = np.random.default_rng(3)

mix_l = np.zeros(N)
mix_r = np.zeros(N)
bass_bus = np.zeros(N)  # everything the kick should duck


def add(buf, start, sig, gain=1.0):
    i = int(start * SR)
    if i >= N:
        return
    sig = sig[: N - i]
    buf[i:i + len(sig)] += sig * gain


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def kick():
    t = np.arange(int(SR * 0.35)) / SR
    f = 45 + 110 * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 9) * 1.0


def hat(open_=False):
    n = int(SR * (0.22 if open_ else 0.05))
    t = np.arange(n) / SR
    x = rng.standard_normal(n)
    x = np.diff(x, prepend=0)  # crude high-pass
    return x * np.exp(-t * (18 if open_ else 90)) * 0.35


def clap():
    n = int(SR * 0.25)
    t = np.arange(n) / SR
    x = rng.standard_normal(n)
    x = np.diff(x, prepend=0) * 0.6 + x * 0.4
    env = np.exp(-t * 22) + 0.7 * np.exp(-((t - 0.012) % 0.02) * 60) * (t < 0.04)
    return x * env * 0.5


def pluck(freq, length, bright=1.0):
    n = int(SR * length)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k, a in ((1, 1.0), (2, 0.5 * bright), (3, 0.33 * bright), (4, 0.2 * bright)):
        x += a * np.sin(2 * np.pi * freq * k * t)
    x += 0.4 * (2 * ((freq * t) % 1) - 1)  # a little saw
    return x * np.exp(-t * 7.5) * (1 - np.exp(-t * 400))


def bass(freq, length):
    n = int(SR * length)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2 * t)
    x = np.tanh(x * 1.6)
    return x * np.minimum(1, (length - t) * 40) * (1 - np.exp(-t * 300))


def pad(freqs, length):
    n = int(SR * length)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for f in freqs:
        for d in (-0.004, 0.004):
            x += (2 * (((f * (1 + d)) * t) % 1) - 1)
    x /= len(freqs) * 2
    env = np.minimum(1, t * 6) * np.minimum(1, (length - t) * 8)
    return x * env


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    s = 0.0
    for i, v in enumerate(x):
        s = (1 - a) * v + a * s
        y[i] = s
    return y


# Am - F - C - G, bar by bar, root notes and chord tones
PROG = [
    (45, [57, 60, 64]),  # Am
    (41, [53, 57, 60]),  # F
    (48, [55, 60, 64]),  # C
    (43, [55, 59, 62]),  # G
]
ARP = [0, 1, 2, 1, 2, 1, 2, 1]  # chord tone index per eighth note

for bar in range(BARS):
    root, chord = PROG[bar % 4]
    b0 = bar * 4 * BEAT
    last = bar == BARS - 1
    drums = 2 <= bar < BARS - 1  # two bars of intro, then full groove
    build = bar == 1 or bar == 5  # snare-less lift into the drop and the second half
    # bass: offbeat eighths
    if bar >= 2 and not last:
        for e in range(8):
            if e % 2 == 1:
                add(bass_bus, b0 + e * BEAT / 2, bass(midi(root), BEAT / 2 * 0.9), 0.55)
    # kick, clap, hats
    if drums:
        for q in range(4):
            add(bass_bus, b0 + q * BEAT, kick(), 0.95)
        for q in (1, 3):
            add(mix_l, b0 + q * BEAT, clap(), 0.7)
            add(mix_r, b0 + q * BEAT, clap(), 0.7)
        for e in range(8):
            h = hat(open_=(e % 2 == 1))
            g = 0.5 if e % 2 else 0.3
            add(mix_l, b0 + e * BEAT / 2, h, g * 0.9)
            add(mix_r, b0 + e * BEAT / 2, h, g)
    # arp, sixteenth feel on eighths, panned side to side
    if bar >= 0 and not last:
        for e in range(8):
            note = chord[ARP[e]] + (12 if (e % 4 == 3) else 0)
            s = pluck(midi(note + 12), BEAT * 0.9, bright=1.0 + 0.3 * (bar >= 6))
            pan = 0.35 + 0.3 * np.sin(e * 0.9 + bar)
            g = 0.22 if bar < 2 else 0.3
            add(mix_l, b0 + e * BEAT / 2, s, g * (1 - pan))
            add(mix_r, b0 + e * BEAT / 2, s, g * pan)
            # quiet echo
            add(mix_l, b0 + e * BEAT / 2 + BEAT * 0.75, s, g * 0.25 * pan)
            add(mix_r, b0 + e * BEAT / 2 + BEAT * 0.75, s, g * 0.25 * (1 - pan))
    # pad from the drop on
    if bar >= 2 and not last:
        p = pad([midi(n) for n in chord], 4 * BEAT)
        p = lowpass(p, 1800)
        add(mix_l, b0, p, 0.22)
        add(mix_r, b0, p, 0.22)
    # snare-roll style riser before each lift
    if bar in (1, 5, 12):
        n = int(SR * 4 * BEAT)
        t = np.arange(n) / SR
        r = rng.standard_normal(n) * (t / t[-1]) ** 2.2
        r = np.diff(r, prepend=0)
        add(mix_l, b0, r, 0.18)
        add(mix_r, b0, r, 0.18)
    # final hit
    if last:
        add(bass_bus, b0, kick(), 1.0)
        for f in (root + 12, root + 24):
            add(mix_l, b0, pluck(midi(f), 2.0), 0.35)
            add(mix_r, b0, pluck(midi(f), 2.0), 0.35)
        for n in chord:
            add(mix_l, b0, pluck(midi(n + 12), 2.0), 0.28)
            add(mix_r, b0, pluck(midi(n + 12), 2.0), 0.28)

# sidechain: duck everything but the kick on each beat
duck = np.ones(N)
for bar in range(2, BARS - 1):
    for q in range(4):
        i = int((bar * 4 + q) * BEAT * SR)
        j = min(N, i + int(SR * 0.28))
        tt = np.arange(j - i) / SR
        duck[i:j] = np.minimum(duck[i:j], 0.35 + 0.65 * (1 - np.exp(-tt * 14)))
mix_l *= duck
mix_r *= duck
bass_part = bass_bus * duck  # bass ducks under the kick too, kick itself is added raw below

# kick without ducking
kicks = np.zeros(N)
for bar in range(2, BARS):
    for q in range(4 if bar < BARS - 1 else 1):
        add(kicks, (bar * 4 + q) * BEAT, kick(), 1.0)

L = mix_l + bass_part * 0.7 + kicks * 0.55
R = mix_r + bass_part * 0.7 + kicks * 0.55

# fades and normalise
fi = np.minimum(1, t_all / 0.15)
fo = np.minimum(1, (DUR - t_all) / 1.2)
L *= fi * fo
R *= fi * fo
peak = max(np.abs(L).max(), np.abs(R).max())
L = np.tanh(L / peak * 1.25) * 0.88
R = np.tanh(R / peak * 1.25) * 0.88

pcm = (np.stack([L, R], axis=1) * 32767).astype("<i2")
with wave.open(OUT, "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print(f"wrote {OUT}: {DUR:.2f}s, {60 / BEAT:.1f} BPM")
