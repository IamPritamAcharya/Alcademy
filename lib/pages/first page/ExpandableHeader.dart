import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:auto_size_text/auto_size_text.dart'; // Add this import
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:port/pages/first%20page/private_page.dart';

class ExpandableHeader extends StatefulWidget {
  final Map<String, dynamic> theme;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final ValueNotifier<bool> isOnlineNotifier;
  final String? userName;
  final String currentSentence;
  final List subjects;

  const ExpandableHeader({
    Key? key,
    required this.theme,
    this.scaffoldKey,
    required this.isOnlineNotifier,
    this.userName,
    required this.currentSentence,
    required this.subjects,
  }) : super(key: key);

  @override
  _ExpandableHeaderState createState() => _ExpandableHeaderState();
}

class _ExpandableHeaderState extends State<ExpandableHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> theme, double opacity) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Massive hero typography with arrow
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Modified Hello + Name text with AutoSizeText
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color.fromARGB(255, 240, 240, 240),
                              Color(0xFFD1D1D1),
                            ],
                            stops: [0.0, 0.7, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello',
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w200,
                                  height: 0.9,
                                  letterSpacing: -2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(
                                height: 6,
                              ),
                              AutoSizeText(
                                widget.userName ?? 'Explorer',
                                maxLines: 1,
                                minFontSize: 32,
                                maxFontSize: 64,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w800,
                                  height: 0.85,
                                  letterSpacing: -2.5,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      // iOS-style slideable arrow
                      _buildSlider(theme, context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Minimal quote container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LineIcons.lightbulb,
                          color: theme['accent'],
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.currentSentence,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlider(Map<String, dynamic> theme, BuildContext context) {
    double _sliderValue = 0.0;
    final LocalAuthentication localAuth = LocalAuthentication();

    Future<void> _authenticateAndNavigate() async {
      try {
        // Check if biometric authentication is available
        final bool isAvailable = await localAuth.canCheckBiometrics;
        final bool isDeviceSupported = await localAuth.isDeviceSupported();

        if (!isAvailable || !isDeviceSupported) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric authentication not available'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Get available biometric types
        final List<BiometricType> availableBiometrics =
            await localAuth.getAvailableBiometrics();

        if (availableBiometrics.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No biometric authentication methods available'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Attempt authentication
        final bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to access private content',
          options: AuthenticationOptions(
            biometricOnly: false, // Allows PIN/password as fallback
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          // Navigate to private page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivatePage(),
            ),
          );
        } else {
          // Authentication failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on PlatformException catch (e) {
        print('Authentication error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        const double containerWidth = 100;
        const double thumbSize = 48;
        const double padding = 6;
        final double maxOffset = containerWidth - thumbSize - padding * 2;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            double newOffset = localPosition.dx - padding - (thumbSize / 2);
            // Smoother drag sensitivity
            setState(() {
              _sliderValue = (newOffset / maxOffset).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_sliderValue >= 0.8) {
              // Trigger authentication when slider is near the end
              _authenticateAndNavigate();
            }
            setState(() {
              _sliderValue = 0.0; // Reset
            });
          },
          child: Container(
            height: 60,
            width: containerWidth,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: Duration(
                      milliseconds: 300), // Increased for smoother animation
                  curve: Curves.easeInOut, // Smoother easing curve
                  left: padding + (_sliderValue * maxOffset),
                  top: padding,
                  child: Container(
                    height: thumbSize,
                    width: thumbSize,
                    decoration: BoxDecoration(
                      color: theme['accent'],
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _sliderValue >= 0.8
                          ? Icons.fingerprint
                          : Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStats(Map<String, dynamic> theme, double opacity) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value + 10),
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatPill(
                      '${widget.subjects.length}',
                      'Subjects',
                      LineIcons.book,
                      Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatPill(
                      theme['name'],
                      'Theme',
                      LineIcons.palette,
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatPill(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 390,
      collapsedHeight: 64,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double totalHeight = 360;
          final double minHeight = 64;
          final double currentHeight = constraints.maxHeight;
          final double collapseRatio =
              ((totalHeight - currentHeight) / (totalHeight - minHeight))
                  .clamp(0.0, 1.0);

          // Refined scaling
          final double actionSize = 48 - (collapseRatio * 8);
          final double statusFontSize = 13 - (collapseRatio * 1);
          final double horizontalPadding = 24 - (collapseRatio * 4);
          final double verticalPadding = 16 - (collapseRatio * 6);

          // Sharp content fade
          final double contentOpacity = collapseRatio < 0.3
              ? 1.0
              : ((1.0 - collapseRatio) / 0.7).clamp(0.0, 1.0);

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  widget.theme['accent'],
                  widget.theme['primary'],
                  Color.lerp(
                      widget.theme['primary'], widget.theme['secondary'], 0.7)!,
                  widget.theme['primary'],
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                // Add a dark overlay to tone down bright colors
                color: Colors.black.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Compact header bar
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHeaderAction(
                            icon: LineIcons.graduationCap,
                            onTap: () => context.push('/year'),
                            size: actionSize,
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: widget.isOnlineNotifier,
                            builder: (context, isOnline, _) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isOnline
                                            ? Colors.green.shade400
                                            : Colors.orange.shade400,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isOnline
                                                    ? Colors.green
                                                    : Colors.orange)
                                                .withOpacity(0.4),
                                            blurRadius: 3,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOnline ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: statusFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          _buildHeaderAction(
                            icon: LineIcons.bars,
                            onTap: () =>
                                widget.scaffoldKey?.currentState?.openDrawer(),
                            size: actionSize,
                          ),
                        ],
                      ),
                    ),
                    // Hero content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            _buildHeroSection(widget.theme, contentOpacity),
                            const SizedBox(height: 10),
                            _buildCompactStats(widget.theme, contentOpacity),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
