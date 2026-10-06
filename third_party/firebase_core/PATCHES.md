# Built-in Kotlin compatibility patch

Source: firebase_core 4.15.0, downloaded from pub.dev.
Upstream: https://github.com/firebase/flutterfire/tree/main/packages/firebase_core

Only android/build.gradle changes. The fallback applying kotlin-android and its
legacy compiler-options callback are removed. This app requires AGP 9 and enables
android.builtInKotlin=true; Kotlin inherits the Java 17 target from compileOptions.
Flutter 3.47 scans build-file text for KGP declarations and otherwise warns even
when the upstream fallback is inactive. No diagnostic suppression is added.

Dart/native implementation, platform assets, dependency versions, and upstream
licenses are unchanged. Remove this override when Flutter's detector understands
conditional KGP declarations or upstream removes the legacy fallback.
