import 'package:flutter/material.dart';

class GateResource {
  final String title;
  final String subtitle;
  final String url;
  final String? keyUrl;
  final List<String>? subjectCodes;
  final String tag;
  final IconData icon;
  final List<Color> gradient;

  const GateResource({
    required this.title,
    required this.subtitle,
    required this.url,
    this.keyUrl,
    this.subjectCodes,
    required this.tag,
    required this.icon,
    required this.gradient,
  });
}

class GateCategory {
  final String name;
  final IconData icon;
  final Color accent;
  final List<GateResource> resources;

  const GateCategory({
    required this.name,
    required this.icon,
    required this.accent,
    required this.resources,
  });
}
