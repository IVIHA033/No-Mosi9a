# Speech evaluation

Offline tests for the engine: how much speech it cuts and how much music it leaves, with and
without voice protection (`SpeechGuard`). The Python here mirrors the Kotlin engine hop by hop,
and `parity.py` checks that the real Kotlin classes give the same output.

## Setup

```bash
python3 -m venv --system-site-packages ~/.cache/no_mosi9a_lab/venv
~/.cache/no_mosi9a_lab/venv/bin/pip install numpy scipy soundfile pyarrow onnxruntime
cd tool/speech_eval
~/.cache/no_mosi9a_lab/venv/bin/python prepare_data.py     # ~250 MB into ~/.cache/no_mosi9a_lab/data
```

Test material (research use, not shipped):

- Speech: Arabic (FLEURS ar_eg, female; ClArTTS, male) and English (LibriSpeech) recordings.
- Music: the 144 MUSDB18 7-second excerpts, instrumental stems summed; vocal stems for the singing test.

## Scripts

| Script | What it measures |
|---|---|
| `evaluate.py model[:guard] …` | Speech over music at −5/0/5/10 dB: share of speech frames cut by more than 6 dB, music left during speech, before speech and in pauses. |
| `music_eval.py model[:guard] …` | Music without speech: music left and how often the guard switches on by mistake (instrumental), and instruments left under singing (songs). |
| `parity.py file.wav` | Runs the app's Kotlin engine classes on a desktop JVM (`jvm/`, build it first with `../../android/gradlew -p jvm installDist`) and this reference on the same file, and compares them. |

Guard specs are comma-separated: `floor12,ovad` = input speech detector, confirmed by a second
detector on the model output, floor 12 dB below the input while someone talks (the app's *Normal*;
`floor6,ovad` is *Strong*); see `guard.make` for the other knobs (`hangN`, `oholdN`, `othrN`, …).

Models are read from `android/app/src/main/assets/models` (plus `~/.cache/no_mosi9a_lab/models`
for extra ones).
