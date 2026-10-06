import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class RefreshTracker {
  static int refreshCount = 0;
  static DateTime? lastRefreshTime;
  static DateTime? cooldownStartTime;
  static bool isCooldownActive = false;
  static Timer? _cooldownTimer;

  static const Duration cooldownDuration = Duration(minutes: 60);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    refreshCount = prefs.getInt('refreshCount') ?? 0;
    String? lastRefreshTimeStr = prefs.getString('lastRefreshTime');
    if (lastRefreshTimeStr != null) {
      lastRefreshTime = DateTime.parse(lastRefreshTimeStr);
    }
    String? cooldownStartTimeStr = prefs.getString('cooldownStartTime');
    if (cooldownStartTimeStr != null) {
      cooldownStartTime = DateTime.parse(cooldownStartTimeStr);
    }
    isCooldownActive = prefs.getBool('isCooldownActive') ?? false;
  }

  static Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setInt('refreshCount', refreshCount);
    if (lastRefreshTime != null) {
      prefs.setString('lastRefreshTime', lastRefreshTime!.toIso8601String());
    }
    if (cooldownStartTime != null) {
      prefs.setString(
          'cooldownStartTime', cooldownStartTime!.toIso8601String());
    }
    prefs.setBool('isCooldownActive', isCooldownActive);
  }

  static Future<bool> incrementRefreshCount() async {
    if (isCooldownActive) {
      if (DateTime.now().difference(cooldownStartTime!) < cooldownDuration) {
        return false;
      } else {
        refreshCount = 0;
        isCooldownActive = false;
        await saveState();
      }
    }

    if (lastRefreshTime == null ||
        DateTime.now().difference(lastRefreshTime!) > cooldownDuration) {
      refreshCount = 0;
      isCooldownActive = false;
      await saveState();
    }

    refreshCount++;
    lastRefreshTime = DateTime.now();
    await saveState();

    if (refreshCount > 7) {
      _startCooldown();
      await saveState();
      return false;
    }

    return true;
  }

  static void _startCooldown() {
    isCooldownActive = true;
    cooldownStartTime = DateTime.now();
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(cooldownDuration, () {
      refreshCount = 0;
      isCooldownActive = false;
      saveState();
    });
  }

  static void dispose() {
    _cooldownTimer?.cancel();
  }
}
