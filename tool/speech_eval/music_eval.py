"""What the speech guard costs on music without speech.

    python music_eval.py dpdfnet_16k dpdfnet_16k:vadfloor12ovad ...

Instrumental: the 144 MUSDB excerpts without vocals. Reports the music left in the output
(dB vs input, energy over the whole clip after a 0.5 s warm-up) and the share of frames where
the guard was active (a false alarm: nobody talks).
Songs: the same excerpts with their sung vocals. Reports the instruments left (projection of the
output on the vocal stem; the rest is instruments) and the share of frames with the guard active.
"""
import multiprocessing as mp
import os
import sys

import numpy as np

from common import DATA, Model, resample, specs, stream
from evaluate import decompose

_model = None
_music = None


def work(args):
    global _model, _music
    name, spec, idx = args
    if _model is None or _model.name != name:
        _model = Model(name)
    if _music is None:
        _music = np.load(os.path.join(DATA, 'music48k.npz'))
    sr, hop = _model.sr, _model.hop
    acc = resample(_music['acc'][idx], 48000, sr)
    voc = resample(_music['voc'][idx], 48000, sr)
    out = {}
    for kind, x, target in (('inst', acc, None), ('song', acc + voc, voc)):
        gain = 10 ** ((-20 - 10 * np.log10(np.mean(x ** 2) + 1e-12)) / 20)   # play at -20 dBFS
        x = x * gain
        post = None
        if spec:
            import guard
            post = guard.make(spec, _model)
        y, X, Y = stream(_model, x, post)
        skip = int(0.5 * sr) // hop
        active = float(np.mean(post.speaking_trace[skip:])) if post is not None else 0.0
        if target is None:
            e_in = np.sum(np.abs(X[skip:]) ** 2)
            e_out = np.sum(np.abs(Y[skip:]) ** 2)
            out[kind] = (10 * np.log10(e_out / e_in + 1e-20), active)
        else:
            si, so, mi, mo = decompose(_model, Y, specs(_model, target * gain), specs(_model, acc * gain))
            sung = si > si.max() * 1e-3
            sung[:skip] = False
            if sung.sum() < 20:
                out[kind] = None
            else:
                out[kind] = (10 * np.log10(mo[sung].sum() / (mi[sung].sum() + 1e-20) + 1e-20), active)
    return out


if __name__ == '__main__':
    n = len(np.load(os.path.join(DATA, 'music48k.npz'))['acc'])
    with mp.get_context('spawn').Pool(os.cpu_count()) as pool:
        for arg in sys.argv[1:]:
            name, _, spec = arg.partition(':')
            rows = pool.map(work, [(name, spec, i) for i in range(n)], chunksize=2)
            inst = np.array([r['inst'] for r in rows])
            song = np.array([r['song'] for r in rows if r['song'] is not None])
            # energy-average the leak over clips, and show the worst clips
            lk = lambda a: 10 * np.log10(np.mean(10 ** (a / 10)))
            print(f'== {arg}\n  instrumental: music left {lk(inst[:, 0]):6.1f} dB (worst clip {inst[:, 0].max():6.1f}),'
                  f' guard active {100 * inst[:, 1].mean():4.1f}% of frames, clips with any: {int((inst[:, 1] > 0).sum())}/{len(inst)}'
                  f'\n  songs:        instruments left under singing {lk(song[:, 0]):6.1f} dB,'
                  f' guard active {100 * song[:, 1].mean():4.1f}% of frames', flush=True)
