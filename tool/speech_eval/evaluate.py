"""Speech over music, run through the engine: how much speech is cut, how much music is left.

    python evaluate.py dpdfnet_16k dpdfnet_16k:vadfloor12 dpdfnet2_48k:vadfloor12 ...

Each test: 2 s of music, then a real speech recording over the same music (looped), then
0.5 s of music. Speech-to-music ratios -5, 0, 5, 10 dB. The output is decomposed per frame
and band by projecting it on the clean speech (the rest is leaked music).

Columns:
  cut>6dB      share of speech frames that lost more than 6 dB of their speech (choppy words)
  lost>15dB    share of speech frames whose speech is practically gone
  loud cut     same, counting only the louder half of speech frames (what you clearly hear)
  speech dB    overall speech level change
  music@speech music left during speech, vs. the music that was there
  music alone  music left before anyone speaks (the "silence" promise)
  music@pause  music left in pauses between sentences
"""
import json
import multiprocessing as mp
import os
import sys
import time

import numpy as np

from common import DATA, MODEL_LAG, Model, resample, specs, stream

SNRS = (-5, 0, 5, 10)
LEAD, TAIL = 2.0, 0.5

_speech = _music = None


def material():
    global _speech, _music
    if _speech is None:
        _speech = dict(np.load(os.path.join(DATA, 'speech48k.npz')))
        _music = np.load(os.path.join(DATA, 'music48k.npz'))['acc']
    return _speech, _music


def loop_to(x, n, sr):
    xf = int(0.05 * sr)
    ramp = np.linspace(0, 1, xf, dtype=np.float32)
    out = x.copy()
    while len(out) < n:
        out = np.concatenate([out[:-xf], out[-xf:] * (1 - ramp) + x[:xf] * ramp, x[xf:]])
    return out[:n]


def rms_db(x):
    return 10 * np.log10(np.mean(np.asarray(x, np.float64) ** 2) + 1e-20)


def cases(per_speech=2, seed=1):
    speech, music = material()
    rng = np.random.default_rng(seed)
    return [(k, int(rng.integers(len(music))), snr) for k in sorted(speech) for snr in SNRS for _ in range(per_speech)]


def build(key, music_idx, snr, sr):
    speech, music = material()
    s = speech[key]
    lead, tail = int(LEAD * 48000), int(TAIL * 48000)
    n = lead + len(s) + tail
    sp = np.zeros(n, np.float32)
    sp[lead:lead + len(s)] = s
    m = loop_to(music[music_idx].astype(np.float32), n, 48000)
    m = m * 10 ** ((-23 - snr - rms_db(m)) / 20)
    return resample(sp, 48000, sr), resample(m, 48000, sr)


def bands(nbins, sr):
    """~1.5 ERB wide bands, at least 4 bins, for the projection."""
    df = sr / 2 / (nbins - 1)
    edges = [0]
    while edges[-1] < nbins:
        f = edges[-1] * df
        edges.append(min(nbins, edges[-1] + max(4, int(np.ceil(1.5 * 24.7 * (4.37 * f / 1000 + 1) / df)))))
    return edges


def decompose(model, Y, S, M):
    """Per frame: speech energy in/out (projection on the clean speech) and music in/out (the rest)."""
    T = len(Y)
    Sa = np.zeros_like(Y)
    Ma = np.zeros_like(Y)
    Sa[MODEL_LAG:] = S[:T - MODEL_LAG]
    Ma[MODEL_LAG:] = M[:T - MODEL_LAG]
    kmax = int(8000 / (model.sr / 2) * (model.bins - 1)) + 1   # speech references are 16 kHz recordings
    si, so, mi, mo = (np.zeros(T) for _ in range(4))
    for a, b in zip(*(lambda e: (e[:-1], e[1:]))(bands(model.bins, model.sr))):
        if a >= kmax:
            break
        sb, yb = Sa[:, a:b], Y[:, a:b]
        ss = np.sum(np.abs(sb) ** 2, 1)
        g = np.sum(yb * np.conj(sb), 1) / (ss + 1e-20)
        si += ss
        so += np.abs(g) ** 2 * ss
        mi += np.sum(np.abs(Ma[:, a:b]) ** 2, 1)
        mo += np.sum(np.abs(yb - g[:, None] * sb) ** 2, 1)
    return si, so, mi, mo


def measure(model, s, m, guard_spec=None):
    post = None
    if guard_spec:
        import guard
        post = guard.make(guard_spec, model)
    y, X, Y = stream(model, s + m, post)
    si, so, mi, mo = decompose(model, Y, specs(model, s), specs(model, m))
    hop, sr = model.hop, model.sr
    active = si > si.max() * 1e-3
    loud = si > np.median(si[active])
    idx = np.arange(len(si))
    first = int(np.argmax(active))
    lead = (idx > int(0.5 * sr) // hop) & (idx < first - 2)
    pause = ~active & (idx > first)
    db = lambda a, b: float(10 * np.log10(a / (b + 1e-20) + 1e-20))
    ret = so / (si + 1e-20)
    return dict(
        cut=float(np.mean(ret[active] < 10 ** -0.6)),
        loud_cut=float(np.mean(ret[loud] < 10 ** -0.6)),
        lost=float(np.mean(ret[active] < 10 ** -1.5)),
        speech_db=db(so[active].sum(), si[active].sum()),
        music_speech_db=db(mo[active].sum(), mi[active].sum()),
        music_alone_db=db(mo[lead].sum(), mi[lead].sum()),
        music_pause_db=db(mo[pause].sum(), mi[pause].sum()),
    )


_model = None


def work(args):
    global _model
    name, guard_spec, case = args
    if _model is None or _model.name != name:
        _model = Model(name)
    s, m = build(*case, sr=_model.sr)
    r = measure(_model, s, m, guard_spec)
    r['snr'] = case[2]
    r['key'] = case[0]
    return r


COLS = [('cut', 'cut>6dB', '%'), ('lost', 'lost>15dB', '%'), ('loud_cut', 'loud cut', '%'), ('speech_db', 'speech dB', 'f'),
        ('music_speech_db', 'music@speech', 'f'), ('music_alone_db', 'music alone', 'f'),
        ('music_pause_db', 'music@pause', 'f')]


def summarize(rows, label):
    lines = [f'== {label}', ' SNR ' + ''.join(f'{c[1]:>14s}' for c in COLS)]
    for snr in SNRS:
        rs = [r for r in rows if r['snr'] == snr]
        vals = []
        for key, _, kind in COLS:
            v = float(np.mean([r[key] for r in rs]))
            vals.append(f'{v * 100:13.1f}%' if kind == '%' else f'{v:14.1f}')
        lines.append(f'{snr:4d} ' + ''.join(vals))
    print('\n'.join(lines), flush=True)


if __name__ == '__main__':
    out_dir = os.path.join(DATA, '..', 'results')
    os.makedirs(out_dir, exist_ok=True)
    all_cases = cases()
    with mp.get_context('spawn').Pool(os.cpu_count()) as pool:
        for arg in sys.argv[1:]:
            name, _, spec = arg.partition(':')
            t0 = time.time()
            rows = pool.map(work, [(name, spec, c) for c in all_cases], chunksize=2)
            json.dump(rows, open(os.path.join(out_dir, arg.replace(':', '+') + '.json'), 'w'))
            summarize(rows, arg)
            print(f'   ({time.time() - t0:.0f} s, {len(rows)} cases)', flush=True)
