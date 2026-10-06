import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/firebase_options.dart';
import 'package:port/core/config/config_service.dart';
import 'package:port/core/storage/github_cache_migration.dart';
import 'package:port/features/notifications/data/notification_service.dart';
import 'package:port/features/notifications/data/background_notification_handler.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    debugPrint('Skipping Firebase initialization on Linux');
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    debugPrint('Background message handler registered');
  }

  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  await migrateGitHubContentCache(prefs);
  final bool isOnboardingComplete =
      prefs.getBool('onboarding_complete') ?? false;

  await ConfigService.loadCachedConfig();
  runApp(MyApp(isOnboardingComplete: isOnboardingComplete));
  unawaited(ConfigService.fetchAndUpdateConfig());
}
