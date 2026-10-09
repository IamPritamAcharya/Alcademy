import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:port/features/private_space/presentation/private_page.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/journal_cover.dart';
import 'package:port/features/home/presentation/widgets/home_entrance.dart';

class HomeHeader extends StatelessWidget {
  final ValueNotifier<bool> isOnlineNotifier;
  final String? userName;
  final String currentSentence;
  final VoidCallback onMenu;
  final int? resourceCount;

  const HomeHeader({
    super.key,
    required this.isOnlineNotifier,
    this.userName,
    required this.currentSentence,
    required this.onMenu,
    this.resourceCount,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'alcademy.',
                  style: TextStyle(
                    color: AppStyle.text,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isOnlineNotifier,
                builder: (context, online, _) => Semantics(
                  label: online ? 'Online' : 'Offline',
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: online ? AppStyle.blue : AppStyle.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        online ? 'ONLINE' : 'OFFLINE',
                        style: AppStyle.eyebrow.copyWith(
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Open menu',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded, color: AppStyle.text),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '$_greeting, ${userName ?? 'Explorer'}.',
            style: const TextStyle(color: AppStyle.text, fontSize: 20),
          ),

          const SizedBox(height: 22),
          HomeEntrance(
            child: JournalCover(
              key: const ValueKey('home-hero'),
              child: CustomPaint(
                painter: _JournalTexturePainter(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'THE STUDENT JOURNAL',
                              style: AppStyle.eyebrow.copyWith(
                                color: AppStyle.paper,
                                fontSize: 9,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _DateStamp(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        key: const ValueKey('hero-headline-slot'),
                        height: 68,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _GreetingHeadline(
                                sentence: currentSentence,
                              ),
                            ),
                            if (MediaQuery.sizeOf(context).width >= 360 &&
                                MediaQuery.textScalerOf(context).scale(43) <=
                                    54) ...[
                              const SizedBox(width: 12),
                              const _AnimatedBook(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppStyle.rule, height: 1),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _ResourceSummary(count: resourceCount),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppStyle.text,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              side: const BorderSide(color: AppStyle.muted),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () => _openPrivateSpace(context),
                            icon: const Icon(
                              Icons.fingerprint_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'Private',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivateSpace(BuildContext context) async {
    final LocalAuthentication localAuth = LocalAuthentication();
    try {
      final bool isAvailable = await localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final List<BiometricType> availableBiometrics = await localAuth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No biometric authentication methods available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access private content',
        options: AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );

      if (didAuthenticate) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivatePage()),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Authentication error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ResourceSummary extends StatelessWidget {
  final int? count;
  const _ResourceSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == null
        ? 'A space for everything you’re learning.'
        : '$count resources. All within reach.';
    final text = AutoSizeText(
      label,
      key: ValueKey(label),
      maxLines: 1,
      minFontSize: 10,
      maxFontSize: 12,
      stepGranularity: .5,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppStyle.paper, fontSize: 12, height: 1.5),
    );
    if (MediaQuery.disableAnimationsOf(context)) return text;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      child: text,
    );
  }
}

class _GreetingHeadline extends StatelessWidget {
  final String sentence;
  const _GreetingHeadline({required this.sentence});

  @override
  Widget build(BuildContext context) {
    final text = AutoSizeText(
      sentence,
      key: ValueKey(sentence),
      maxLines: 2,
      minFontSize: 14,
      maxFontSize: 32,
      stepGranularity: .5,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppStyle.text,
        fontSize: 32,
        height: 1.05,
        fontWeight: FontWeight.bold,
        letterSpacing: -.8,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return text;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .06),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: text,
    );
  }
}

class _BookMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = AppStyle.cover;
    canvas.save();
    canvas.translate(5, 16);
    canvas.rotate(-.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 56, 67),
        const Radius.circular(3),
      ),
      Paint()..color = AppStyle.accent,
    );
    canvas.drawLine(
      const Offset(9, 0),
      const Offset(9, 67),
      dark..strokeWidth = 1,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(14, 7);
    canvas.rotate(.09);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 48, 66),
        const Radius.circular(3),
      ),
      Paint()..color = AppStyle.blue,
    );
    canvas.drawLine(
      const Offset(8, 0),
      const Offset(8, 66),
      dark..strokeWidth = 1,
    );
    final ribbon = Path()
      ..moveTo(31, 0)
      ..lineTo(39, 0)
      ..lineTo(39, 23)
      ..lineTo(35, 19)
      ..lineTo(31, 23)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = AppStyle.cover);
    for (final y in [38.0, 44.0, 50.0]) {
      canvas.drawLine(
        Offset(16, y),
        Offset(36, y),
        Paint()
          ..color = AppStyle.cover.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
    final sparkle = Path()
      ..moveTo(4, 0)
      ..lineTo(6, 5)
      ..lineTo(11, 7)
      ..lineTo(6, 9)
      ..lineTo(4, 14)
      ..lineTo(2, 9)
      ..lineTo(-3, 7)
      ..lineTo(2, 5)
      ..close();
    canvas.drawPath(sparkle, Paint()..color = AppStyle.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DateStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppStyle.muted),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}',
        style: const TextStyle(
          color: AppStyle.paper,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _JournalTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppStyle.paper.withValues(alpha: .035)
      ..strokeWidth = .5;
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final fold = Path()
      ..moveTo(size.width - 22, 0)
      ..lineTo(size.width - 22, 22)
      ..lineTo(size.width, 22)
      ..close();
    canvas.drawPath(
      fold,
      Paint()..color = AppStyle.paper.withValues(alpha: .13),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedBook extends StatefulWidget {
  const _AnimatedBook();
  @override
  State<_AnimatedBook> createState() => _AnimatedBookState();
}

class _AnimatedBookState extends State<_AnimatedBook>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: 50,
        height: 64,
        child: FittedBox(
          child: SizedBox(
            width: 65,
            height: 83,
            child: AnimatedBuilder(
              animation: _controller,
              child: CustomPaint(painter: _BookMarkPainter()),
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  0,
                  math.sin(_controller.value * 2 * math.pi) * 3,
                ),
                child: Transform.rotate(
                  angle: math.sin(_controller.value * 2 * math.pi) * .035,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
