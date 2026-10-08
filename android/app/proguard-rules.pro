# ONNX Runtime calls back into its Java classes from native code.
-keep class ai.onnxruntime.** { *; }

# Shizuku binder glue is looked up by name.
-keep class rikka.shizuku.** { *; }
-keep class moe.shizuku.** { *; }

# Our method/event channel handlers and services are referenced from the manifest
# or by name from Dart; keep them readable in crash reports.
-keep class com.nomosi9a.app.** { *; }
