# No Mosi9a — بلا موسيقى

Removes the music from videos playing in **any** app (YouTube, Instagram, Facebook, TikTok…), live, on the phone, and lets you hear only the voices. Free, open source, and fully offline: the app has no internet permission.

## بالدارجة

- **شنو كيدير؟** كيشد الصوت ديال أي تطبيق (يوتيوب، إنستا، فيسبوك…)، كيدوزو على ذكاء اصطناعي فالتليفون كيحيد الموسيقى وكيخلي غير الكلام، وكيسكّت الصوت الأصلي باش تسمع غير الكلام.
- **كيفاش نخدمو؟**
  1. ثبت الـ APK.
  2. دير التفعيل مرة وحدة: من الكمبيوتر بـ `./tool/adb_setup.sh`، ولا بلا كمبيوتر بـ Shizuku (التطبيق كيشرح).
  3. ضغط على الزر الكبير، ومن بعد حل يوتيوب ولا إنستا عادي.
- **واش 100%؟** الموسيقى ديال الآلات كتحيد تقريباً كاملة (فالتجارب: من الصوت الكامل حتى للسكات، −60 حتى −100 dB). ولكن الغنا صوت بنادم، داكشي علاش صوت المغني يقدر يبقى.
- **الكلام كيتقطع؟** ملي تكون الموسيقى طالعة بحال الكلام، الذكاء الاصطناعي كان كيحسب شي حروف موسيقى وكيحيدهم. دابا كاين «حماية الكلام» (الإعدادات): جوج ديال الكواشف كيسمعو واش كاين شي واحد كيهضر، وملي كيتفقو، التطبيق ما كيخليش الكلمات يتقطعو. ملي ما كاين حتى كلام، الموسيقى كتحيد كاملة بحال ديما. «قوية» إلا بقا الكلام كيتقطع، «متوقفة» إلا بغيتي أقصى حذف.
- **التطبيقات اللي كتمنع:** Netflix، Spotify، Chrome وشي ألعاب كيمنعو أندرويد يشد الصوت ديالهم، كيبقاو كيخدمو عادي بالموسيقى.

## How it works

```
YouTube / Instagram / …  ──►  Android mixer  ──►  speaker        ✗ silenced by us
        │                                                         (DynamicsProcessing, −200 dB,
        │                                                          on that app's audio session)
        └──►  AudioPlaybackCapture: a copy of the sound, taken before session effects
                   │
                   ▼
             DPDFNet (ONNX Runtime, on the phone): keeps voices, removes everything else
                   │
             Speech guard: while someone talks, words the model would cut are kept
                   │
                   ▼
             our AudioTrack  ──►  speaker / headphones                ✓ what you hear
```

1. **Capture**: a foreground service uses `MediaProjection` + `AudioPlaybackCaptureConfiguration` to receive the mixed media/game audio of every app that allows it (our own app is excluded).
2. **Mute the original**: Android does not let apps mute each other, so the app reads the audio policy dump (needs the `DUMP` permission, granted once over ADB or Shizuku) to find each app's audio session, and attaches a `DynamicsProcessing` effect with −200 dB input gain to it. Capture taps a track *before* session effects run, so the app is silent on the speaker but not in our copy. Mutes stay attached for 15 minutes after a session goes quiet, because players reuse their session for the next video, which is then muted from its first sample.
3. **Clean**: 10 ms hops go through a causal STFT → [DPDFNet](https://huggingface.co/Ceva-IP/DPDFNet) (dual-path RNN on top of DeepFilterNet2, Apache-2.0) → inverse STFT, all in Kotlin with a zero-allocation inner loop (pinned ONNX Runtime tensors, ping-pong recurrent state).
4. **Protect speech** (*Voice protection*, on by default): the network is a speech enhancer, and when music is about as loud as the voice it takes parts of words for music and drops them. `SpeechGuard` runs [Silero VAD](https://github.com/snakers4/silero-vad) twice: on the original sound (it hears words even where the model cut them, 40 ms before they are played, because the model lags its input) and on what the model kept (some instrumental music fools a single detector; the model then removes it and the second detector hears nothing). Only when both hear speech does the guard keep every frequency of the output at most 12 dB (*Normal*) or 6 dB (*Strong*) below the input, so the cut parts of words come back. When nobody talks it does nothing: music alone is still removed completely.
5. **Play**: the cleaned voice goes out through a normal media `AudioTrack`, so the volume keys work as usual.

The same technique (capture + session mute) is what RootlessJamesDSP uses for its rootless mode; the code here is an independent implementation.

## Measured results

Offline test on speech (LibriSpeech, English and Arabic TTS) mixed with seven music tracks (orchestra, piano ragtime, electronic, drum & bass, waltz, blues with singing), fed hop by hop exactly like the phone does:

| Model | Instrumental music alone | Speech + music, SI-SDR gain (0 / 5 / 10 dB SNR) | Clean speech kept (SI-SDR) | Time per 10 ms hop (M2, 1 thread) |
|---|---|---|---|---|
| **Full** — DPDFNet-2 48 kHz (shipped) | **−88 to −108 dB** (silence) | +10.5 / +8.7 / +6.6 dB | 25 dB | 1.3 ms |
| **Balanced** — DPDFNet-2 16 kHz (shipped) | −62 to −68 dB | +10.4 / +8.5 / +6.4 dB | 24 dB | 0.9 ms |
| **Light** — DPDFNet baseline 16 kHz (shipped) | −50 to −69 dB, weaker right after a pause | +9.5 / +7.8 / +5.8 dB | 23 dB | 0.35 ms |
| DeepFilterNet3 48 kHz (rejected) | −21 to −41 dB | +6.9 / +6.2 / +5.2 dB | 38 dB | 1.6 ms |
| Singing voice (any model) | only −3.5 to −6 dB | — | — | — |

The Kotlin engine was also run on a desktop JVM against the Python reference: outputs match to 84 dB (full) and 130 dB (light) SI-SDR, i.e. bit-for-bit up to float rounding.

End-to-end on an Android 15 emulator (the real APK, a test app playing speech over music as `USAGE_MEDIA`): the test app's session got the mute effect, the music-only intro went from −25 dBFS in the capture to −122 dBFS in what the app played, and the phone's output matched the desktop reference fed with the same captured audio to 44.5 dB (the +3 dB voice boost and the limiter are the only difference). Setup through `tool/adb_setup.sh`, the quick settings tile, excluding an app and the Arabic (RTL) interface were checked the same way.

### Voice protection

`tool/speech_eval` (see its README) mixes 18 real recordings (Arabic women and men, English) with 144 instrumental excerpts at a speech-to-music ratio of 0 dB (music as loud as the voice), runs them through the engine and splits the output into speech and leftover music by projecting it on the clean recording:

| Model | Protection | Speech frames cut by > 6 dB | Speech practically gone (> 15 dB) | Music before anyone speaks | Music in pauses between words |
|---|---|---|---|---|---|
| Full | Off | 18.2 % | 6.9 % | −61 dB | −35 dB |
| Full | **Normal** | **7.3 %** | **0.6 %** | −61 dB | −16 dB |
| Full | Strong | 2.0 % | 0.6 % | −61 dB | −10 dB |
| Balanced | Off | 19.8 % | 7.3 % | −48 dB | −32 dB |
| Balanced | **Normal** | **8.7 %** | **0.9 %** | −47 dB | −16 dB |
| Balanced | Strong | 2.4 % | 0.8 % | −47 dB | −10 dB |
| Light | Off | 24.9 % | 10.0 % | −45 dB | −31 dB |
| Light | **Normal** | **12.6 %** | **1.2 %** | −45 dB | −16 dB |
| Light | Strong | 3.3 % | 0.9 % | −45 dB | −10 dB |

With louder music (−5 dB) Normal still brings "speech gone" from 11.1 % to 2.9 % (Full) and from 19.1 % to 7.5 % (Light). Music without speech is unaffected: on the 144 instrumental excerpts alone, the guard switched on in a single one, and the music left changed by at most 1 dB. In songs it switches on during about 9 % of the sung frames (Silero VAD tells speech from singing), so the instruments under the singer rise by only 1–2 dB. The second detector earns its place on the music-only intro of `docs/demo/1_original.wav`: it fools the input detector for over a second, which alone would let that music through at −12 dB; with both, the Full model keeps it at −124 dBFS (the Light model, which itself lets part of that intro through, goes from −56 to −42 dBFS there). The two detectors and the extra inverse FFT cost about 0.1 ms per 10 ms hop on an M2 (1 % of real time); the speed test behind `Auto` includes them.

On the Android 15 emulator (the real APK) Silero VAD runs in ONNX Runtime Android, the protected output matched this reference at 42.6 dB (the voice boost and limiter being the only difference, 19 dB without the guard in the reference), the live card showed "Voice detected · words protected" during speech, and switching the level applied immediately without restarting the audio.

`Auto` quality times the models on the phone at first start, from Full down to Light, and keeps the first one that needs ≤ 45 % of real time; if the phone later falls behind (heat, background load), it steps down one level by itself.

## Requirements

- Android 10 or newer (playback capture does not exist before), 64-bit ARM recommended.
- A one-time activation from a computer (ADB) or from the phone itself (Shizuku).
- iOS is not possible: iOS does not let an app hear or silence other apps.

## Build and install

```bash
flutter pub get
flutter build apk --release --split-per-abi
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
./tool/adb_setup.sh          # one-time activation (USB debugging on)
```

Without a computer: install [Shizuku](https://shizuku.rikka.app/), start it with Wireless debugging, then tap **Grant with Shizuku** in the app's setup screen.

The one-time activation grants:

| Command | Why |
|---|---|
| `pm grant com.nomosi9a.app android.permission.DUMP` | See which app owns which audio session, so its original sound can be muted. Required. |
| `appops set com.nomosi9a.app PROJECT_MEDIA allow` | Skip Android's capture pop-up on every start, and keep working with the screen off (Android 15+). Recommended. |

Release builds are currently signed with the debug key (`android/app/build.gradle.kts`); use your own keystore before sharing the APK.

## Using it

- Tap the big button, then open YouTube, Instagram, Facebook… The home screen shows the live levels (original vs. what you hear), the delay, the processor load and which apps are being cleaned.
- Add the **No music** tile to Quick Settings to switch it without leaving the video app.
- **Settings**: quality (Auto / Full / Balanced / Light), voice protection (Off / Normal / Strong), delay (Low / Normal / Stable), apps to leave untouched (a Quran or podcast app, for example), language (Arabic, French, English), battery optimization.

## Limitations

- **Singing** is a human voice: the instruments go, the singer can stay.
- With **voice protection** on, a faint trace of the music stays under the voice while someone talks and in the short pauses between their words (about −16 dB with Normal, −10 dB with Strong). Music without speech is still removed completely. Set it to Off for the strongest removal, at the price of words being cut when the music is loud.
- Apps that forbid capture (Netflix, Spotify, Chrome, some games) cannot be cleaned; they keep playing unchanged and are listed as “blocks processing”.
- When an app creates a brand-new player, its first few tens of milliseconds can be heard before the session is found and muted. Players that reuse their session (most do, per app) are muted from the start afterwards.
- The cleaned voice lags the picture by roughly 70–150 ms (model 50 ms + buffers); Bluetooth adds its own delay.
- Android allows one screen/audio capture at a time: starting a screen recorder stops the app, and vice versa.
- AudioFlinger keeps a session effect alive while the app's track exists, even if the process that created it dies. So if No Mosi9a is force-stopped (or updated) mid-video, that video can stay muted. The app cleans this up by itself the next time its process starts (opening it, pulling down quick settings, or right after an update), and a crash handler releases the mutes before a crash. Stopping it normally never leaves anything behind.
- Another equalizer app that uses `DynamicsProcessing` (Wavelet, JamesDSP…) can fight over the same effect.

## Project layout

```
lib/                                  Flutter UI (Arabic / French / English)
  src/engine/                         method/event channel client and models
  src/ui/                             home, setup wizard, settings, help
  l10n/                               ARB translations
android/app/src/main/kotlin/com/nomosi9a/app/
  engine/EngineService.kt             foreground service: projection, muter, pipeline, model choice
  engine/AudioPipeline.kt             capture → model → limiter → AudioTrack real-time loop
  engine/DpdfnetDenoiser.kt           ONNX Runtime wrapper (pinned tensors, state ping-pong)
  engine/SpeechGuard.kt               voice protection: keeps words the model would cut
  engine/SileroVad.kt                 speech detector used by the guard (pinned tensors)
  engine/dsp/                         mixed-radix FFT (KissFFT port), streaming STFT, decimator
  engine/session/                     audio-policy dump parser, session muter, mute effect
  engine/ToggleTileService.kt         quick settings tile (+ ProjectionActivity)
  platform/                           settings store, permissions, Shizuku
android/app/src/main/assets/models/   dpdfnet2_48k.onnx, dpdfnet2_16k.onnx, dpdfnet_16k.onnx, silero_vad.onnx
tool/adb_setup.sh                     one-time activation script
tool/speech_eval/                     Python reference of the engine + speech/music measurements
```

## Development

- Kotlin unit tests (FFT against a naive DFT, STFT transparency, decimator, dump parsers for Android 10–16 formats):
  `cd android && ./gradlew :app:testDebugUnitTest`
- Debug builds can save what the engine hears and plays: `adb shell run-as com.nomosi9a.app touch files/debug_record`, start the engine, then pull `files/debug_in_<rate>.f32` and `files/debug_out_<rate>.f32` (raw float32 mono, first 40 s).
- Speech/music measurements and the Kotlin-vs-Python check: `tool/speech_eval/README.md`.
- The app strips the INTERNET permission and ONNX Runtime's telemetry provider from the release manifest on purpose. Debug builds keep INTERNET because Flutter's hot reload needs it.

## Credits

- [DPDFNet](https://huggingface.co/Ceva-IP/DPDFNet) by Ceva — Apache-2.0
- [Silero VAD](https://github.com/snakers4/silero-vad) — MIT
- [ONNX Runtime](https://onnxruntime.ai/) — MIT
- [Shizuku](https://github.com/RikkaApps/Shizuku-API) — Apache-2.0
- [HiddenApiBypass](https://github.com/LSPosed/AndroidHiddenApiBypass) — Apache-2.0
- [KISS FFT](https://github.com/mborgerding/kissfft) — BSD-3-Clause (ported to Kotlin)
