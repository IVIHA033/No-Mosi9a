"""Downloads and prepares the test material into $NM_LAB/data (default ~/.cache/no_mosi9a_lab).

Speech (real recordings, normalised to -23 dBFS active level, 48 kHz):
  - Arabic, female: Google FLEURS ar_eg test (CC-BY-4.0)
  - Arabic, male:   MBZUAI ClArTTS test (CC-BY-4.0)
  - English:        LibriSpeech dev-clean sample (CC-BY-4.0)
Music: MUSDB18 7-second excerpts (144 songs), instrumental stems summed (drums+bass+other),
plus the vocal stem kept apart for singing tests. Research use.
"""
import glob
import io
import json
import os
import subprocess
import time
import urllib.request
import zipfile

import numpy as np
import pyarrow.parquet as pq
import soundfile as sf

from common import DATA, resample

HF = 'https://huggingface.co/api/datasets'


def fetch(url, path):
    if os.path.exists(path):
        return path
    for attempt in range(8):
        try:
            subprocess.run(['curl', '-sSL', '-C', '-', '-m', '3600', '-o', path + '.part', url], check=True)
            os.rename(path + '.part', path)
            return path
        except subprocess.CalledProcessError:
            time.sleep(3)
    raise RuntimeError('download failed: ' + url)


def fleurs_arabic(n=6):
    out = []
    off = 0
    while len(out) < n and off < 60:
        url = f'https://datasets-server.huggingface.co/rows?dataset=google/fleurs&config=ar_eg&split=test&offset={off}&length=3'
        try:
            rows = json.load(urllib.request.urlopen(url, timeout=60))['rows']
        except Exception:
            time.sleep(3)
            continue
        off += 3
        for r in rows:
            row = r['row']
            if not 6 <= row['num_samples'] / 16000 <= 17:
                continue
            src = row['audio'][0]['src'] if isinstance(row['audio'], list) else row['audio']['src']
            s, sr = sf.read(io.BytesIO(urllib.request.urlopen(src, timeout=120).read()), dtype='float32')
            out.append((f"ar_f_{row['id']}", s, sr))
    return out[:n]


def speech():
    clips = fleurs_arabic()
    rows = pq.read_table(fetch(f'{HF}/MBZUAI/ClArTTS/parquet/default/test/0.parquet',
                               os.path.join(DATA, 'clartts_test.parquet'))).to_pylist()
    for i, r in enumerate([r for r in rows if 6 <= r['duration'] <= 16][:8]):
        clips.append((f'ar_m_{i}', np.array(r['audio'], np.float32), r['sampling_rate']))
    rows = pq.read_table(fetch(f'{HF}/hf-internal-testing/librispeech_asr_dummy/parquet/clean/validation/0.parquet',
                               os.path.join(DATA, 'libri_dummy.parquet'))).to_pylist()
    n = 0
    for r in rows:
        s, sr = sf.read(io.BytesIO(r['audio']['bytes']), dtype='float32')
        if 6 <= len(s) / sr <= 16 and n < 4:
            n += 1
            clips.append((f'en_{n}', s, sr))
    out = {}
    for key, s, sr in clips:
        s = resample(s, sr, 48000)
        e = (s[:len(s) // 480 * 480].reshape(-1, 480) ** 2).mean(1)
        level = np.sqrt(e[e > e.max() * 1e-4].mean())
        out[key] = (s * 10 ** (-23 / 20) / level).astype(np.float32)
    np.savez(os.path.join(DATA, 'speech48k.npz'), **out)
    print('speech clips:', len(out), sorted(out))


def music():
    z = fetch('https://zenodo.org/records/3270814/files/MUSDB18-7-STEMS.zip', os.path.join(DATA, 'musdb7.zip'))
    root = os.path.join(DATA, 'musdb')
    if not os.path.isdir(root):
        zipfile.ZipFile(z).extractall(root)

    def dec(f, graph):
        r = subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-filter_complex', graph, '-map', '[o]',
                            '-f', 'f32le', '-'], capture_output=True, check=True)
        return np.frombuffer(r.stdout, np.float32)

    acc, voc = [], []
    mono = 'pan=mono|c0=0.5*c0+0.5*c1,aresample=48000[o]'
    for f in sorted(glob.glob(os.path.join(root, '*', '*.stem.mp4'))):
        a = dec(f, '[0:1][0:2][0:3]amix=inputs=3:normalize=0,' + mono)
        v = dec(f, '[0:4]' + mono)
        n = min(len(a), len(v))
        acc.append(a[:n])
        voc.append(v[:n])
    n = min(len(a) for a in acc)
    np.savez(os.path.join(DATA, "music48k.npz"), acc=np.stack([a[:n] for a in acc]), voc=np.stack([v[:n] for v in voc]))
    print('music clips:', len(acc))


if __name__ == '__main__':
    os.makedirs(DATA, exist_ok=True)
    if not os.path.exists(os.path.join(DATA, 'speech48k.npz')):
        speech()
    if not os.path.exists(os.path.join(DATA, 'music48k.npz')):
        music()
