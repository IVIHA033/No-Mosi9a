"""Shared paths and a Python mirror of the app's streaming engine.

The engine (StreamingStft + DpdfnetDenoiser) is reproduced hop by hop:
frame = [history(hop), input(hop)] * vorbis -> rfft -> model -> irfft * vorbis -> overlap-add.
"""
import os
from math import gcd

import numpy as np
import onnxruntime as ort
from scipy.signal import resample_poly

LAB = os.environ.get('NM_LAB', os.path.expanduser('~/.cache/no_mosi9a_lab'))
DATA = os.path.join(LAB, 'data')
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
APP_MODELS = os.path.join(REPO, 'android', 'app', 'src', 'main', 'assets', 'models')
EXTRA_MODELS = os.path.join(LAB, 'models')

# Model output frame t belongs to input frame t - MODEL_LAG (measured; 50 ms total with framing).
MODEL_LAG = 4


def model_path(name):
    for d in (APP_MODELS, EXTRA_MODELS):
        p = os.path.join(d, name + '.onnx')
        if os.path.exists(p):
            return p
    raise FileNotFoundError(name)


def session(path):
    so = ort.SessionOptions()
    so.intra_op_num_threads = 1
    so.inter_op_num_threads = 1
    so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    return ort.InferenceSession(path, so, providers=['CPUExecutionProvider'])


def resample(x, sr_from, sr_to):
    if sr_from == sr_to:
        return np.asarray(x, np.float32)
    g = gcd(sr_from, sr_to)
    return resample_poly(x, sr_to // g, sr_from // g).astype(np.float32)


def vorbis(n):
    half = n / 2.0
    s = np.sin(0.5 * np.pi * (np.arange(n) + 0.5) / half)
    return np.sin(0.5 * np.pi * s * s).astype(np.float32)


class Model:
    def __init__(self, name):
        self.name = name
        self.sess = session(model_path(name))
        m = self.sess.get_modelmeta().custom_metadata_map
        self.sr = int(m['sample_rate'])
        self.hop = int(m['hop_length'])
        self.win = int(m['window_length'])
        self.bins = self.win // 2 + 1
        erb = [float(v) for v in m['erb_norm_init'].split(',')]
        spec = [float(v) for v in m['spec_norm_init'].split(',')]
        self.init_state = np.zeros(int(m['state_size']), np.float32)
        self.init_state[:len(erb)] = erb
        self.init_state[len(erb):len(erb) + len(spec)] = spec
        ins = {i.name: i.shape for i in self.sess.get_inputs()}
        outs = {o.name: o.shape for o in self.sess.get_outputs()}
        self.spec_in = next(k for k, v in ins.items() if len(v) == 4)
        self.state_in = next(k for k, v in ins.items() if len(v) == 1)
        self.spec_out = next(k for k, v in outs.items() if len(v) == 4)
        self.state_out = next(k for k, v in outs.items() if len(v) == 1)
        self.window = vorbis(self.win)
        self.state = self.init_state.copy()

    def reset(self):
        self.state = self.init_state.copy()

    def frame(self, X):
        spec = np.stack([X.real, X.imag], -1).astype(np.float32)[None, None]
        out, self.state = self.sess.run([self.spec_out, self.state_out],
                                        {self.spec_in: spec, self.state_in: self.state})
        return out[0, 0, :, 0] + 1j * out[0, 0, :, 1]


def stream(model, x, post=None):
    """Runs x (at model.sr) hop by hop like the phone. post.frame(X, Y) may edit each output
    frame; post.hop(samples) sees each input hop first. Returns y, input frames, output frames."""
    model.reset()
    hop, win, w = model.hop, model.win, model.window
    n = len(x) // hop
    hist = np.zeros(win - hop, np.float32)
    ola = np.zeros(win, np.float32)
    y = np.zeros(n * hop, np.float32)
    Xs, Ys = [], []
    for t in range(n):
        chunk = x[t * hop:(t + 1) * hop]
        if post is not None:
            post.hop(chunk)
        frame = np.concatenate([hist, chunk])
        hist = frame[hop:].copy()
        X = np.fft.rfft(frame * w)
        Y = model.frame(X)
        if post is not None:
            Y = post.frame(X, Y)
        Xs.append(X)
        Ys.append(Y)
        ola += np.fft.irfft(Y, win).astype(np.float32) * w
        y[t * hop:(t + 1) * hop] = ola[:hop]
        ola = np.concatenate([ola[hop:], np.zeros(hop, np.float32)])
    return y, np.array(Xs), np.array(Ys)


def specs(model, x):
    """The engine's analysis framing, for reference signals (speech or music alone)."""
    hop, win, w = model.hop, model.win, model.window
    xp = np.concatenate([np.zeros(win - hop, np.float32), x])
    return np.array([np.fft.rfft(xp[t * hop:t * hop + win] * w) for t in range(len(x) // hop)])
