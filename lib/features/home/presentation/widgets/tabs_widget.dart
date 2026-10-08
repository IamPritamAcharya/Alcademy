import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:port/features/blog/presentation/blog_page.dart';
import 'package:port/features/success_stories/presentation/success_stories_page.dart';
import 'package:port/features/expenses/presentation/expense_tracker_page.dart';
import 'package:port/features/college_resources/presentation/erp_page.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/home_pressable.dart';

class TabsWidget extends StatelessWidget {
  final Function(String) onTabPressed;
  const TabsWidget({super.key, required this.onTabPressed});

  @override
  Widget build(BuildContext context) {
    final tabs =
        <
          ({
            String name,
            String detail,
            IconData icon,
            Color accent,
            Widget Function() page,
          })
        >[
          (
            name: 'Expenses',
            detail: 'Your spending',
            icon: Icons.account_balance_wallet_outlined,
            accent: AppStyle.gold,
            page: () => const ExpenseTrackerPage(),
          ),
          (
            name: 'ERP',
            detail: 'Student portal',
            icon: Icons.school_outlined,
            accent: AppStyle.blue,
            page: () => AcademicWebViewPage(),
          ),
          (
            name: 'Blog',
            detail: 'Campus reads',
            icon: Icons.article_outlined,
            accent: AppStyle.accent,
            page: () => MarkdownListPage(),
          ),
          (
            name: 'Stories',
            detail: 'Inspiration',
            icon: Icons.emoji_events_outlined,
            accent: AppStyle.lilac,
            page: () => SuccessStoriesPage(),
          ),
        ];
    Widget tool(int index) {
      final tab = tabs[index];
      return HomePressable(
        entranceOrder: index,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => tab.page()),
          );
          onTabPressed(tab.name);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomPaint(
                painter: _ShortcutStamp(tab.accent),
                child: SizedBox(
                  width: 42,
                  height: 48,
                  child: Icon(tab.icon, color: tab.accent, size: 27),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.name,
                      style: const TextStyle(
                        color: AppStyle.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.detail,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AnimatedAccentStrip(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: tool(0)),
                      Expanded(child: tool(1)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(child: tool(2)),
                      Expanded(child: tool(3)),
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
}

class _AnimatedAccentStrip extends StatefulWidget {
  const _AnimatedAccentStrip();

  @override
  State<_AnimatedAccentStrip> createState() => _AnimatedAccentStripState();
}

class _AnimatedAccentStripState extends State<_AnimatedAccentStrip>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_foreground && TickerMode.valuesOf(context).enabled && !reducedMotion) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      if (reducedMotion) _motion.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: SizedBox(
      width: 2,
      child: RepaintBoundary(
        child: CustomPaint(painter: _AccentStripPainter(_motion)),
      ),
    ),
  );
}

class _AccentStripPainter extends CustomPainter {
  final Animation<double> motion;
  final Paint _ink = Paint();

  _AccentStripPainter(this.motion) : super(repaint: motion);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = motion.value * 2 * math.pi;
    // Periodic easing matches both color and velocity across the loop seam.
    final blend = (1 - math.cos(phase)) / 2;
    final drift = (1 - math.cos(phase + math.pi / 2)) / 2;
    final bounds = Offset.zero & size;
    _ink.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(AppStyle.gold, AppStyle.lilac, blend)!.withValues(alpha: .5),
        Color.lerp(
          AppStyle.lilac,
          AppStyle.blue,
          drift,
        )!.withValues(alpha: .18),
      ],
    ).createShader(bounds);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(2)),
      _ink,
    );
  }

  @override
  bool shouldRepaint(_AccentStripPainter oldDelegate) =>
      oldDelegate.motion != motion;
}

/// A concentric ring with two soft highlights frames each shortcut.
class _ShortcutStamp extends CustomPainter {
  final Color color;
  const _ShortcutStamp(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1;
    final bounds = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .055),
            color.withValues(alpha: .055),
            color.withValues(alpha: .025),
          ],
          stops: const [0, .65, 1],
        ).createShader(bounds),
    );
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        transform: const GradientRotation(-.35 * math.pi),
        colors: [
          color.withValues(alpha: .06),
          color.withValues(alpha: .45),
          color.withValues(alpha: .45),
          color.withValues(alpha: .06),
          color.withValues(alpha: .06),
          color.withValues(alpha: .18),
          color.withValues(alpha: .18),
          color.withValues(alpha: .06),
          color.withValues(alpha: .06),
        ],
        stops: const [0, .07, .29, .38, .5, .57, .79, .88, 1],
      ).createShader(bounds);
    canvas.drawCircle(centre, radius, ink);
  }

  @override
  bool shouldRepaint(_ShortcutStamp oldDelegate) => oldDelegate.color != color;
}
