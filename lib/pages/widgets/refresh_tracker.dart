import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class RefreshTracker {
  static int refreshCount = 0; // Tracks the number of refreshes
  static DateTime? lastRefreshTime; // Stores the timestamp of the last refresh
  static DateTime?
      cooldownStartTime; // Stores the timestamp of when the cooldown started
  static bool isCooldownActive = false; // Indicates if the cooldown is active
  static Timer? _cooldownTimer;

  static const Duration cooldownDuration =
      Duration(minutes: 60); // Set cooldown time to 1 hour

  static Future<void> init() async {
    // Load saved data from shared preferences
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

  /// Call this method when a refresh is triggered.
  /// Returns `true` if the refresh is allowed, or `false` if under cooldown.
  static Future<bool> incrementRefreshCount() async {
    if (isCooldownActive) {
      // Check if cooldown is still active
      if (DateTime.now().difference(cooldownStartTime!) < cooldownDuration) {
        return false; // Cooldown is still active, block refresh
      } else {
        // Cooldown period has ended, reset counter and deactivate cooldown
        refreshCount = 0;
        isCooldownActive = false;
        await saveState(); // Save updated state
      }
    }

    if (lastRefreshTime == null ||
        DateTime.now().difference(lastRefreshTime!) > cooldownDuration) {
      // Reset the counter if the last refresh was more than 1 hour ago
      refreshCount = 0;
      isCooldownActive = false;
      await saveState(); // Save updated state
    }

    refreshCount++;
    lastRefreshTime = DateTime.now();
    await saveState(); // Save updated state

    if (refreshCount > 7) {
      // Trigger cooldown if the count exceeds 3
      _startCooldown();
      await saveState(); // Save updated state
      return false; // Block refresh due to excessive usage
    }

    return true; // Allow refresh
  }

  /// Starts the cooldown period and resets the counter after the cooldownDuration
  static void _startCooldown() {
    isCooldownActive = true;
    cooldownStartTime =
        DateTime.now(); // Store the timestamp when cooldown starts
    _cooldownTimer?.cancel(); // Cancel any existing timer
    _cooldownTimer = Timer(cooldownDuration, () {
      refreshCount = 0; // Reset counter after cooldown duration
      isCooldownActive = false; // Deactivate cooldown
      saveState(); // Save updated state
    });
  }

  /// Dispose of the cooldown timer when no longer needed
  static void dispose() {
    _cooldownTimer?.cancel();
  }
}
