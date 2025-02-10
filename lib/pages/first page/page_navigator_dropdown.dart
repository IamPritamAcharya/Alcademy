import 'dart:ui';

import 'package:flutter/material.dart';

class ExtendedAppBarWithSlidingEffect extends StatelessWidget {
  final Color themeColor;

  const ExtendedAppBarWithSlidingEffect({
    Key? key,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> pages = [
      {
        'icon': Icons
            .apartment_rounded, // Better represents amenities or facilities
        'route': '/amenities',
        'label': 'Amenities'
      },
      {
        'icon': Icons
            .menu_book_rounded, // Represents syllabus or educational materials
        'route': '/syllabus',
        'label': 'Syllabus'
      },
      {
        'icon': Icons.event_available_outlined, // Represents holidays or events
        'route': '/holiday',
        'label': 'Holiday'
      },
      {
        'icon': Icons
            .functions_rounded, // Represents calculations (SGPA, GPA, etc.)
        'route': '/sgpa',
        'label': 'SGPA'
      },
      {
        'icon': Icons.view_agenda_outlined,
        'route': '/calendar',
        'label': 'Calendar'
      },
    ];

    final double topPadding = MediaQuery.of(context).padding.top;
    final double availableWidth = MediaQuery.of(context).size.width;

    // Calculate icon size and spacing dynamically
    const double maxIconSize = 25;
    const double minIconSpacing = 10;
    final double totalSpacing = (pages.length - 1) * minIconSpacing;
    final double calculatedIconSize =
        (availableWidth - totalSpacing - 20) / pages.length; // Subtract padding
    final double iconSize = calculatedIconSize.clamp(0, maxIconSize);

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 10,
        bottom: 10,
        left: 10,
        right: 10,
      ),
      decoration: _buildBackgroundDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: pages.map((page) {
          return _buildIcon(
            context: context,
            icon: page['icon'] as IconData? ?? Icons.error,
            route: page['route'] as String? ?? '/',
            label: page['label'] as String? ?? 'Unknown',
            size: iconSize,
          );
        }).toList(),
      ),
    );
  }

  /// Builds the background decoration with a bottom border.
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      border: const Border(
        bottom: BorderSide(
          color: Colors.white24,
          width: 1,
        ),
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(15),
        bottomRight: Radius.circular(15),
      ),
      color: Colors.transparent,
    );
  }

  /// Builds a single interactive icon with tooltip and animated decoration.
  Widget _buildIcon({
    required BuildContext context,
    required IconData icon,
    required String route,
    required String label,
    required double size,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Tooltip(
        message: label,
        textStyle: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100), // Circle shape
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0), // Frosted effect
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(size * 0.3),
              decoration: _buildIconDecoration(),
              child: Icon(
                icon,
                color: Colors.white,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the decoration for each icon with a glassmorphic effect.
  BoxDecoration _buildIconDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0), // Semi-transparent background
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.4), // Subtle white border
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05), // Minimal shadow
          blurRadius: 6,
          offset: const Offset(0, 2), // Light elevation
        ),
      ],
    );
  }
}
