import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:port/shared/theme/app_style.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppStyle.accent,
    onPrimary: AppStyle.onAccent,
    secondary: AppStyle.blue,
    onSecondary: AppStyle.background,
    tertiary: AppStyle.lilac,
    surface: AppStyle.surface,
    onSurface: AppStyle.text,
    onSurfaceVariant: AppStyle.muted,
    outline: AppStyle.rule,
    error: AppStyle.danger,
    onError: AppStyle.background,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppStyle.background,
    canvasColor: AppStyle.background,
    fontFamily: 'ProductSans',
    fontFamilyFallback: const ['Roboto'],
  );
  const border = OutlineInputBorder(
    borderRadius: AppStyle.radius,
    borderSide: BorderSide(color: AppStyle.rule),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppStyle.text,
      displayColor: AppStyle.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppStyle.background,
      foregroundColor: AppStyle.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppStyle.pageTitle,
      iconTheme: IconThemeData(color: AppStyle.text, size: 22),
    ),
    cardTheme: const CardThemeData(
      color: AppStyle.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppStyle.radius),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppStyle.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppStyle.radius),
      titleTextStyle: AppStyle.pageTitle,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppStyle.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppStyle.surface,
      labelStyle: TextStyle(color: AppStyle.muted),
      hintStyle: TextStyle(color: AppStyle.muted),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyle.radius,
        borderSide: BorderSide(color: AppStyle.accent, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppStyle.accent,
      selectionColor: AppStyle.blue.withValues(alpha: .25),
      selectionHandleColor: AppStyle.accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppStyle.accent,
        foregroundColor: AppStyle.onAccent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppStyle.radius),
        textStyle: const TextStyle(
          fontFamily: 'ProductSans',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppStyle.accent,
        foregroundColor: AppStyle.onAccent,
        shape: const RoundedRectangleBorder(borderRadius: AppStyle.radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppStyle.text,
        side: const BorderSide(color: AppStyle.rule),
        shape: const RoundedRectangleBorder(borderRadius: AppStyle.radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppStyle.accent),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppStyle.accent,
      foregroundColor: AppStyle.onAccent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppStyle.radius),
    ),
    dividerTheme: const DividerThemeData(color: AppStyle.rule, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppStyle.accent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppStyle.surface,
      contentTextStyle: TextStyle(
        color: AppStyle.text,
        fontFamily: 'ProductSans',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppStyle.radius),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppStyle.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppStyle.radius),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppStyle.surface,
      selectedColor: AppStyle.cover,
      side: const BorderSide(color: AppStyle.rule),
      labelStyle: const TextStyle(
        color: AppStyle.text,
        fontFamily: 'ProductSans',
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppStyle.radius),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
