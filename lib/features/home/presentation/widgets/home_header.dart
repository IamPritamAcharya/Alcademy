import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:port/features/private_space/presentation/private_page.dart';
import 'package:port/features/home/presentation/widgets/home_style.dart';

class HomeHeader extends StatelessWidget {
  final ValueNotifier<bool> isOnlineNotifier;
  final String? userName;
  final String currentSentence;
  final VoidCallback onMenu;

  const HomeHeader({
    super.key,
    required this.isOnlineNotifier,
    this.userName,
    required this.currentSentence,
    required this.onMenu,
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
                    color: HomeStyle.text,
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
                          color: online ? HomeStyle.text : HomeStyle.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        online ? 'ONLINE' : 'OFFLINE',
                        style: HomeStyle.eyebrow.copyWith(
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
                icon: const Icon(Icons.menu_rounded, color: HomeStyle.text),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '$_greeting, ${userName ?? 'Explorer'}.',
            style: const TextStyle(color: HomeStyle.text, fontSize: 20),
          ),
          const SizedBox(height: 5),
          Text(
            currentSentence,
            style: const TextStyle(
              color: HomeStyle.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: HomeStyle.forest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE EVERYDAY STUDENT COMPANION',
                    style: HomeStyle.eyebrow.copyWith(
                      color: HomeStyle.sage,
                      fontSize: 9,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Text(
                          'Your next\nchapter.',
                          style: TextStyle(
                            color: HomeStyle.text,
                            fontSize: 43,
                            height: 1.03,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 65,
                          height: 83,
                          child: CustomPaint(painter: _BookMarkPainter()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFF52675B), height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'A space for everything you’re learning.',
                          style: TextStyle(
                            color: HomeStyle.sage,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: HomeStyle.text,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _openPrivateSpace(context),
                        icon: const Icon(Icons.lock_outline_rounded, size: 15),
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

class _BookMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = HomeStyle.sage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 12, size.width - 12, size.height - 14),
        const Radius.circular(2),
      ),
      line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(9, 5, size.width - 12, size.height - 14),
        const Radius.circular(2),
      ),
      Paint()..color = HomeStyle.sage,
    );
    canvas.drawLine(
      const Offset(18, 5),
      Offset(18, size.height - 9),
      Paint()
        ..color = HomeStyle.forest
        ..strokeWidth = 1,
    );
    final bookmark = Path()
      ..moveTo(38, 5)
      ..lineTo(48, 5)
      ..lineTo(48, 33)
      ..lineTo(43, 28)
      ..lineTo(38, 33)
      ..close();
    canvas.drawPath(bookmark, Paint()..color = HomeStyle.accent);
    for (final y in [46.0, 53.0, 60.0]) {
      canvas.drawLine(
        Offset(26, y),
        Offset(47, y),
        Paint()
          ..color = HomeStyle.forest.withValues(alpha: .35)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
