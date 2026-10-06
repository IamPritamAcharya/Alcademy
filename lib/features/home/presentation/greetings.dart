import 'package:flutter/material.dart';
import 'dart:math';

final Map<String, List<String>> timeBasedGreetings = {
  "earlyMorning": [
    "Rise and shine!",
    "Good morning, early bird!",
    "Time for a fresh start!",
    "Who even wakes up this early?",
    "Sun’s up, but my soul isn’t.",
    "5 more minutes… forever.",
    "Early morning = regrets already.",
  ],
  "morning": [
    "Good morning!",
    "Another day, another chance!",
    "Morning vibes activated!",
    "Why is morning a thing?",
    "Still tired. Send caffeine.",
    "Let’s pretend to be productive.",
    "Survived the alarm, barely.",
  ],
  "midday": [
    "Good afternoon!",
    "Keep it going!",
    "Lunch break mood!",
    "Is napping a sport yet?",
    "I’m running on snacks and hope.",
    "Halfway through, kinda.",
    "Assignments? What assignments?",
  ],
  "lateAfternoon": [
    "Stay focused!",
    "Afternoon hustle!",
    "Tea time energy!",
    "Just surviving, you?",
    "Productivity is a myth.",
    "Countdown to dinner starts now.",
    "Brain: Offline. Send help.",
  ],
  "earlyEvening": [
    "Twilight is here!",
    "Evening chill mode!",
    "Sunset vibes!",
    "Let the procrastination marathon begin.",
    "Should I study or nap? Neither.",
    "One more scroll, I promise.",
  ],
  "evening": [
    "Good evening!",
    "Relax and unwind!",
    "Evening serenity!",
    "Pretending tomorrow doesn’t exist.",
    "Time to overthink everything.",
    "Netflix, then panic later.",
    "Can I skip to the weekend?",
  ],
  "lateEvening": [
    "Time to slow down!",
    "Good night vibes!",
    "Moonlit moments!",
    "Netflix and avoid responsibilities.",
    "Sleep is optional, right?",
    "Dreaming of deadlines already.",
    "Why am I still awake?",
  ],
  "midnight": [
    "Sleep mode: ON!",
    "Stargazing time!",
    "Deep night calm!",
    "Midnight snacks are life.",
    "Why do my best ideas come now?",
    "Tomorrow’s problems can wait.",
    "Is it late, or is it early?",
  ],
};

String getRandomSentence({String? previous}) {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 8) {
    return _getRandomGreeting("earlyMorning", previous: previous);
  } else if (hour >= 8 && hour < 12) {
    return _getRandomGreeting("morning", previous: previous);
  } else if (hour >= 12 && hour < 15) {
    return _getRandomGreeting("midday", previous: previous);
  } else if (hour >= 15 && hour < 18) {
    return _getRandomGreeting("lateAfternoon", previous: previous);
  } else if (hour >= 18 && hour < 19) {
    return _getRandomGreeting("earlyEvening", previous: previous);
  } else if (hour >= 19 && hour < 21) {
    return _getRandomGreeting("evening", previous: previous);
  } else if (hour >= 21 && hour < 23) {
    return _getRandomGreeting("lateEvening", previous: previous);
  } else {
    return _getRandomGreeting("midnight", previous: previous);
  }
}

String _getRandomGreeting(String timeCategory, {String? previous}) {
  final greetings = timeBasedGreetings[timeCategory]!;
  final candidates = greetings
      .where((greeting) => greeting != previous)
      .toList();
  final choices = candidates.isEmpty ? greetings : candidates;
  return choices[Random().nextInt(choices.length)];
}

IconData getIconForTimeOfDay() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 8) {
    return Icons.wb_sunny_outlined;
  } else if (hour >= 8 && hour < 12) {
    return Icons.wb_sunny;
  } else if (hour >= 12 && hour < 15) {
    return Icons.cloud_queue;
  } else if (hour >= 15 && hour < 18) {
    return Icons.cloud;
  } else if (hour >= 18 && hour < 19) {
    return Icons.wb_twilight;
  } else if (hour >= 19 && hour < 21) {
    return Icons.nights_stay_outlined;
  } else if (hour >= 21 && hour < 23) {
    return Icons.nights_stay;
  } else {
    return Icons.brightness_3;
  }
}
