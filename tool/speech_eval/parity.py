"""Checks that the app's Kotlin engine (run on a desktop JVM) matches this Python reference."""
import subprocess, sys, os
import numpy as np, soundfile as sf
from common import LAB, Model, model_path, resample, stream
import guard

HARNESS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'jvm', 'build', 'install', 'engine-harness', 'bin', 'engine-harness')
LEVELS = {'off': 0, 'normal': 12, 'strong': 6}


def sisdr(ref, est):
    a = np.dot(est, ref) / np.dot(ref, ref)
    return 10 * np.log10(np.sum((a * ref) ** 2) / np.sum((a * ref - est) ** 2))


if __name__ == '__main__':
    wav = sys.argv[1]
    x0, sr0 = sf.read(wav, dtype='float32')
    if x0.ndim > 1:
        x0 = x0.mean(1)
    for name in ['dpdfnet2_48k', 'dpdfnet_16k']:
        m = Model(name)
        x = resample(x0, sr0, m.sr)
        x = x[:len(x) // m.hop * m.hop]
        for level, floor in LEVELS.items():
            g = guard.make(f'floor{floor},ovad', m) if floor else None
            y, _, _ = stream(m, x, g)
            tmp = os.path.join(LAB, 'parity_in.f32')
            x.astype('<f4').tofile(tmp)
            subprocess.run([HARNESS, model_path(name), model_path('silero_vad'), level, tmp, tmp + '.out'], check=True)
            k = np.fromfile(tmp + '.out', '<f4')
            spk = open(tmp + '.out.speaking').read()
            extra = ''
            if g is not None:
                py_speaking = ''.join('1' if s else '0' for s in g.speaking_trace)
                extra = f', speech-state frames that differ: {sum(a != b for a, b in zip(spk, py_speaking))}/{len(spk)}'
            print(f'{name:14s} {level:7s} Kotlin vs Python SI-SDR {sisdr(y, k):6.1f} dB{extra}')
