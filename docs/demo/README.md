# Before / after

Produced by the app's own Kotlin engine (run on a desktop JVM with the same ONNX models), not by a separate script.

| File | What |
|---|---|
| `1_original.wav` | 4 s of music, then English and Arabic speech over the music |
| `2_cleaned_full.wav` | Full quality (48 kHz). The music-only intro drops from −26 dBFS to −114 dBFS: silence. |
| `3_cleaned_light.wav` | Light quality (16 kHz), for older phones. Intro drops to −54 dBFS. |

Sources: music “Vibe Ace” by Kevin MacLeod (incompetech.com), licensed under Creative Commons Attribution 3.0; speech generated with the macOS text-to-speech voices Samantha and Majed.
