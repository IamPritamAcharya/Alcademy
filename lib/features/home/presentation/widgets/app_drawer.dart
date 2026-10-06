import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:port/features/home/presentation/widgets/home_pressable.dart';
import 'package:port/features/profile/data/profile_repository.dart';
import 'package:port/shared/theme/app_style.dart';

class UniqueDrawer extends StatefulWidget {
  final Color themeColor;
  const UniqueDrawer({super.key, required this.themeColor});

  @override
  State<UniqueDrawer> createState() => _UniqueDrawerState();
}

class _UniqueDrawerState extends State<UniqueDrawer> {
  String _name = 'Guest User';
  String _branch = 'Alcademy Student';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await ProfileRepository.getUserName();
    final branch = await ProfileRepository.getUserBranch();
    if (!mounted) return;
    setState(() {
      _name = name ?? 'Guest User';
      _branch = branch ?? 'Alcademy Student';
    });
  }

  void _open(String route) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final compactHeight = 78 + scale.scale(18) * 2.4;
    return Drawer(
      width: math.min(MediaQuery.sizeOf(context).width * .92, 390),
      backgroundColor: AppStyle.background,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ALCADEMY / MENU',
                            style: AppStyle.eyebrow,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close navigation menu',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 21),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: AppStyle.rule),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Explore.',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -2.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _profile(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('01 / STUDY', style: AppStyle.eyebrow),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(height: 1, color: AppStyle.rule),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _tile(
                            label: 'Syllabus',
                            route: '/syllabus',
                            icon: Icons.auto_stories_outlined,
                            height: compactHeight * 2 + 12,
                            fill: AppStyle.paper,
                            ink: AppStyle.background,
                            accent: AppStyle.background,
                            order: 1,
                            feature: true,
                            caption: 'THE STUDY SHELF',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _tile(
                                label: 'SGPA',
                                route: '/sgpa',
                                icon: Icons.calculate_outlined,
                                height: compactHeight,
                                accent: AppStyle.accent,
                                order: 2,
                              ),
                              const SizedBox(height: 12),
                              _tile(
                                label: 'Results',
                                route: '/result',
                                icon: Icons.assessment_outlined,
                                height: compactHeight,
                                accent: AppStyle.blue,
                                order: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('02 / CAMPUS', style: AppStyle.eyebrow),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(height: 1, color: AppStyle.rule),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _tile(
                      label: 'Calendar',
                      route: '/calendar',
                      icon: Icons.calendar_month_outlined,
                      height: 74 + scale.scale(24) * 2.4,
                      accent: AppStyle.gold,
                      order: 4,
                      wide: true,
                      caption: 'SCHEDULES & EVENTS',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tile(
                            label: 'Amenities',
                            route: '/amenities',
                            icon: Icons.location_on_outlined,
                            height: compactHeight,
                            accent: AppStyle.blue,
                            order: 5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tile(
                            label: 'Holidays',
                            route: '/holiday',
                            icon: Icons.wb_sunny_outlined,
                            height: compactHeight,
                            accent: AppStyle.gold,
                            order: 5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _tile(
                      label: 'Notifications',
                      route: '/notifications',
                      icon: Icons.notifications_none_rounded,
                      height: 74 + scale.scale(24) * 2.4,
                      accent: AppStyle.lilac,
                      order: 6,
                      wide: true,
                      caption: 'CAMPUS UPDATES',
                    ),
                    const SizedBox(height: 22),
                    HomePressable(
                      color: Colors.transparent,
                      onTap: () => _open('/about'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.blur_on_rounded,
                              color: AppStyle.muted,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'About',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppStyle.muted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: AppStyle.rule),
                    const SizedBox(height: 12),
                    const Text(
                      'Made by Pritam Acharya',
                      style: TextStyle(color: AppStyle.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profile() => HomePressable(
    color: AppStyle.surface.withValues(alpha: .4),
    side: const BorderSide(color: AppStyle.rule),
    borderRadius: BorderRadius.circular(8),
    onTap: () => _open('/user'),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 52,
            decoration: BoxDecoration(
              color: AppStyle.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppStyle.rule),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppStyle.paper,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _branch,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppStyle.muted),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Profile',
                  style: TextStyle(fontSize: 11, color: AppStyle.lilac),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.north_east_rounded, color: AppStyle.muted, size: 19),
        ],
      ),
    ),
  );

  Widget _tile({
    required String label,
    required String route,
    required IconData icon,
    required double height,
    required Color accent,
    required int order,
    Color fill = AppStyle.surface,
    Color ink = AppStyle.text,
    bool feature = false,
    bool wide = false,
    String? caption,
  }) => SizedBox(
    height: height,
    child: HomePressable(
      entranceOrder: order,
      color: fill,
      borderRadius: BorderRadius.circular(8),
      onTap: () => _open(route),
      child: Stack(
        children: [
          if (feature)
            Positioned(
              top: 54,
              left: -20,
              right: -20,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: -.18,
                  child: Icon(
                    icon,
                    size: 136,
                    color: ink.withValues(alpha: .13),
                  ),
                ),
              ),
            ),
          if (wide)
            Positioned(
              right: -14,
              top: -18,
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: .16,
                  child: Icon(
                    icon,
                    size: 112,
                    color: accent.withValues(alpha: .07),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accent, size: 26),
                    const Spacer(),
                    Icon(
                      Icons.north_east_rounded,
                      color: ink.withValues(alpha: .5),
                      size: 16,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (caption != null) ...[
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink.withValues(alpha: .6),
                          fontSize: 9,
                          letterSpacing: 1.2,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: feature || wide ? 24 : 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.6,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
