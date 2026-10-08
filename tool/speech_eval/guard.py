"""Python reference of the app's SpeechGuard: Silero VAD on the input decides when a
person is talking; while they are, the model's output is never allowed to drop below a
floor relative to the input, so words the model would cut stay audible."""
import re

import numpy as np

from common import MODEL_LAG, model_path, session


class SileroVad:
    """Silero VAD v5 at 16 kHz: 512-sample chunks with 64 samples of context (official wrapper)."""
    CHUNK, CONTEXT = 512, 64

    def __init__(self):
        self.s = session(model_path('silero_vad'))
        self.reset()

    def reset(self):
        self.state = np.zeros((2, 1, 128), np.float32)
        self.ctx = np.zeros(self.CONTEXT, np.float32)

    def chunk(self, x):
        inp = np.concatenate([self.ctx, x]).astype(np.float32)[None]
        out, self.state = self.s.run(None, {'input': inp, 'state': self.state, 'sr': np.array(16000, np.int64)})
        self.ctx = x[-self.CONTEXT:].copy()
        return float(out[0, 0])


def lowpass_taps(n, cutoff):
    """Blackman-windowed sinc, cutoff as a fraction of the input sample rate, unity DC gain."""
    m = np.arange(n) - (n - 1) / 2
    h = 2 * cutoff * np.sinc(2 * cutoff * m) * np.blackman(n)
    return (h / h.sum()).astype(np.float32)


class Decimator:
    """48 kHz -> 16 kHz (factor 3), causal FIR; same taps as the Kotlin port."""
    TAPS = 63

    def __init__(self, factor):
        self.factor = factor
        self.h = lowpass_taps(self.TAPS, 7200 / 48000) if factor > 1 else None
        self.buf = np.zeros(self.TAPS - 1, np.float32)
        self.phase = 0

    def process(self, x):
        if self.factor == 1:
            return x
        z = np.concatenate([self.buf, x])
        out = []
        i = self.phase
        while i < len(x):
            seg = z[i:i + self.TAPS]
            out.append(float(np.dot(seg[::-1], self.h)))
            i += self.factor
        self.phase = i - len(x)
        self.buf = z[-(self.TAPS - 1):]
        return np.array(out, np.float32)


class Guard:
    def __init__(self, model, floor_db=12.0, hang_ms=200, release_ms=60, thr=0.5, vad=True,
                 out_vad=False, out_hold_ms=1000, out_thr=0.5):
        self.hop_ms = 1000 * model.hop / model.sr
        self.floor = 10 ** (-floor_db / 20) if floor_db else 0.0
        self.hang = int(round(hang_ms / self.hop_ms))
        self.release = min(1.0, self.hop_ms / release_ms)
        self.thr = thr
        self.use_vad = vad
        self.vad = SileroVad() if vad else None
        self.dec = Decimator(model.sr // 16000)
        self.pending = np.zeros(0, np.float32)
        self.prob = 0.0
        self.since = 10 ** 6
        self.w = 0.0 if vad else 1.0
        self.ring = [np.zeros(model.bins, complex) for _ in range(MODEL_LAG + 1)]
        self.speaking_trace = []
        # Second detector on the model's own (pre-guard) output: confirms that the model hears a
        # voice too, so music that fools the input detector is never let through.
        self.out_vad = SileroVad() if out_vad else None
        self.out_dec = Decimator(model.sr // 16000)
        self.out_pending = np.zeros(0, np.float32)
        self.out_prob = 0.0
        self.out_since = 10 ** 6
        self.out_hold = int(round(out_hold_ms / self.hop_ms))
        self.win = model.window
        self.hop_n = model.hop
        self.ola = np.zeros(model.win, np.float32)
        self.out_trace = []
        self.out_thr = out_thr

    def hop(self, x):
        if not self.use_vad:
            return
        self.pending = np.concatenate([self.pending, self.dec.process(x)])
        while len(self.pending) >= SileroVad.CHUNK:
            self.prob = self.vad.chunk(self.pending[:SileroVad.CHUNK])
            self.pending = self.pending[SileroVad.CHUNK:]

    def frame(self, X, Y):
        self.ring = self.ring[1:] + [X]
        xa = self.ring[0]                      # the input frame this output belongs to
        confirmed = True
        if self.out_vad is not None:
            self.ola += np.fft.irfft(Y, len(self.win)).astype(np.float32) * self.win
            self.out_pending = np.concatenate([self.out_pending, self.out_dec.process(self.ola[:self.hop_n].copy())])
            self.ola = np.concatenate([self.ola[self.hop_n:], np.zeros(self.hop_n, np.float32)])
            while len(self.out_pending) >= SileroVad.CHUNK:
                self.out_prob = self.out_vad.chunk(self.out_pending[:SileroVad.CHUNK])
                self.out_pending = self.out_pending[SileroVad.CHUNK:]
            self.out_since = 0 if self.out_prob >= self.out_thr else self.out_since + 1
            confirmed = self.out_since <= self.out_hold
            self.out_trace.append(self.out_prob)
        if self.use_vad:
            self.since = 0 if self.prob >= self.thr else self.since + 1
            target = 1.0 if self.since <= self.hang and confirmed else 0.0
            self.w = target if target >= self.w else self.w + (target - self.w) * self.release
            if self.w < 1e-3:
                self.w = 0.0
        self.speaking_trace.append(self.use_vad and self.since <= self.hang and confirmed)
        w = self.w
        if w <= 0:
            return Y
        ax = np.abs(xa)
        ay = np.abs(Y)
        add = np.maximum(w * self.floor * ax - ay, 0)
        # Raise the magnitude along the input's phase (the model output is ~in phase with it).
        return Y + np.where(ax > 0, add / np.maximum(ax, 1e-30), 0) * xa


def make(spec, model):
    """Comma-separated options: 'floor12,ovad' is the app's Normal, 'floor6,ovad' its Strong.
    floorN: dB below the input while someone talks; ovad: confirm with a detector on the model
    output; novad: no detector (floor always on); hangN, relN, oholdN: ms; thrN, othrN: %."""
    opts = {}
    flags = set()
    for tok in filter(None, spec.split(',')):
        m = re.fullmatch(r'([a-z]+)(\d+)', tok)
        if m:
            opts[m.group(1)] = int(m.group(2))
        else:
            flags.add(tok)
    return Guard(model, floor_db=opts.get('floor', 12), hang_ms=opts.get('hang', 200),
                 release_ms=opts.get('rel', 60), thr=opts.get('thr', 50) / 100, vad='novad' not in flags,
                 out_vad='ovad' in flags, out_hold_ms=opts.get('ohold', 1000), out_thr=opts.get('othr', 50) / 100)
