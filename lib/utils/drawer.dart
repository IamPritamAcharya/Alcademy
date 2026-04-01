import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/onboarding/utils/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UniqueDrawer extends StatefulWidget {
  final Color themeColor;

  const UniqueDrawer({Key? key, required this.themeColor}) : super(key: key);

  @override
  _UniqueDrawerState createState() => _UniqueDrawerState();
}

class _UniqueDrawerState extends State<UniqueDrawer>
    with TickerProviderStateMixin {
  String userName = "Guest User";
  String userEmail = "guest@alcademy.com";
  String? userProfileImage;
  bool _isLoading = true;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();

    _loadUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final savedUserName = await UserData.getUserName();

    userName =
        savedUserName ?? user?.userMetadata?['full_name'] ?? "Guest User";
    userEmail = user?.email ?? "guest@alcademy.com";
    userProfileImage = user?.userMetadata?['avatar_url'];

    if (userProfileImage != null) {
      _imageProvider = NetworkImage(userProfileImage!);
      await precacheImage(_imageProvider!, context);
    } else {
      _imageProvider =
          const AssetImage('lib/file assets/placeholderPerson.png');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<BentoItem> bentoItems = [
      BentoItem(
        icon: LineIcons.user,
        route: '/user',
        label: 'Profile',
        subtitle: 'Manage your account',
        size: BentoSize.large,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.purple.withOpacity(0.6),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.bookOpen,
        route: '/syllabus',
        label: 'Syllabus',
        size: BentoSize.medium,
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.7),
            Colors.teal.withOpacity(0.5),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.calculator,
        route: '/sgpa',
        label: 'SGPA',
        size: BentoSize.medium,
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.7),
            Colors.deepOrange.withOpacity(0.5),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.calendar,
        route: '/calendar',
        label: 'Calendar',
        subtitle: 'View schedules & events',
        size: BentoSize.large,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.indigo.withOpacity(0.8),
            Colors.blue.withOpacity(0.6),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.hotel,
        route: '/amenities',
        label: 'Amenities',
        size: BentoSize.small,
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withOpacity(0.6),
            Colors.blue.withOpacity(0.4),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.calendarWithDayFocus,
        route: '/holiday',
        label: 'Holidays',
        size: BentoSize.small,
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.6),
            Colors.purple.withOpacity(0.4),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.windowRestore,
        route: '/result',
        label: 'Results',
        size: BentoSize.small,
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.6),
            Colors.orange.withOpacity(0.4),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.info,
        route: '/about',
        label: 'About',
        size: BentoSize.small,
        gradient: LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.6),
            Colors.blueGrey.withOpacity(0.4),
          ],
        ),
      ),
      BentoItem(
        icon: LineIcons.bell,
        route: '/notifications',
        label: 'Notifications',
        subtitle: 'View recent alerts & updates',
        size: BentoSize.large,
        gradient: LinearGradient(
          colors: [
            Colors.orangeAccent.withOpacity(0.6),
            Colors.pinkAccent.withOpacity(0.4),
          ],
        ),
      ),
    ];

    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Container(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildBentoGrid(bentoItems),
                  ),
                  SliverToBoxAdapter(
                    child: Divider(
                      color: Colors.white12,
                      height: 0.5,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFooter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      height: 205,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('lib/file assets/collegeBack.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: CustomPaint(
                painter: GeometricPatternPainter(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: _isLoading
                          ? const CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white12,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundImage: _imageProvider,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white.withOpacity(0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alcademy Student Portal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Divider(
              color: Colors.white12,
              height: 0.5,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBentoGrid(List<BentoItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          _buildBentoRow([items[0]]),
          const SizedBox(height: 12),
          _buildBentoRow([items[1], items[2]]),
          const SizedBox(height: 12),
          _buildBentoRow([items[3]]),
          const SizedBox(height: 12),
          _buildBentoRow([items[4], items[5]]),
          const SizedBox(height: 12),
          _buildBentoRow([items[6], items[7]]),
          const SizedBox(height: 12),
          _buildBentoRow([items[8]]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBentoRow(List<BentoItem> items) {
    return Row(
      children: items.map((item) {
        final isLarge = item.size == BentoSize.large;
        return Expanded(
          flex: isLarge ? 2 : 1,
          child: Container(
            margin: EdgeInsets.only(
              right: items.indexOf(item) == items.length - 1 ? 0 : 12,
            ),
            child: _buildBentoCard(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBentoCard(BentoItem item) {
    final isLarge = item.size == BentoSize.large;
    final height = isLarge ? 125.0 : 100.0;

    return GestureDetector(
      onTap: () {
        context.push(item.route);
        Navigator.pop(context);
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: item.gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: (item.gradient.colors.last).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: CardPatternPainter(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: isLarge ? 24 : 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLarge ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isLarge && item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                Icons.arrow_outward,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Text(
        'Alcademy v2.0 - by Pritam Acharya',
        style: TextStyle(
          color: Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

enum BentoSize { small, medium, large }

class BentoItem {
  final IconData icon;
  final String route;
  final String label;
  final String? subtitle;
  final BentoSize size;
  final Gradient gradient;

  BentoItem({
    required this.icon,
    required this.route,
    required this.label,
    this.subtitle,
    required this.size,
    required this.gradient,
  });
}

class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final rect = Rect.fromLTWH(
        size.width * 0.7 + i * 10,
        size.height * 0.2 + i * 8,
        30,
        30,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.7, 0);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
