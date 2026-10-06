# Local Android Gradle compatibility patch

Source: flutter_inappwebview_android 1.1.3 from pub.dev.
Upstream: https://github.com/pichillilorenzo/flutter_inappwebview
Issue: https://github.com/pichillilorenzo/flutter_inappwebview/issues/2852

Only android/build.gradle is changed: both debug and release ProGuard presets
use proguard-android-optimize.txt, which Android Gradle Plugin 9 requires.
Dart and Java sources, public APIs, dependencies, and the upstream license are
unchanged. The app uses this copy through a dependency_overrides path.

Remove the override and this directory once a compatible stable upstream release
is adopted and verified with the existing YouTube player integration.
