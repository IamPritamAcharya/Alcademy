import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UniqueDrawer extends StatelessWidget {
  final Color themeColor;

  const UniqueDrawer({Key? key, required this.themeColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final String userName = user?.userMetadata?['full_name'] ?? "Guest User";
    final String userEmail = user?.email ?? "guest@alcademy.com";
    final String? userProfileImage = user?.userMetadata?['avatar_url'];

    final List<Map<String, dynamic>> pages = [
      {'icon': LineIcons.hotel, 'route': '/amenities', 'label': 'Amenities'},
      {'icon': LineIcons.bookOpen, 'route': '/syllabus', 'label': 'Syllabus'},
      {
        'icon': LineIcons.calendarWithDayFocus,
        'route': '/holiday',
        'label': 'Holiday'
      },
      {'icon': LineIcons.calculator, 'route': '/sgpa', 'label': 'SGPA'},
      {'icon': LineIcons.calendar, 'route': '/calendar', 'label': 'Calendar'},
      {'icon': LineIcons.user, 'route': '/user', 'label': 'Profile'},
      {'icon': LineIcons.rProject, 'route': '/result', 'label': 'Result'},
    ];

    return Drawer(
      backgroundColor: const Color(0xFF1A1D1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Top Section
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://raw.githubusercontent.com/IamPritamAcharya/DATA_hub/main/202412251623130769328728-Photoroom.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF1A1D1E),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: userProfileImage != null
                        ? NetworkImage(userProfileImage)
                        : const NetworkImage(
                            'https://cdn-icons-png.flaticon.com/512/4322/4322991.png',
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 70),

          // User Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Menu Items - Redesigned for a cleaner and bolder look
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () {
                      context.push(page['route'] as String);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(page['icon'] as IconData,
                              color: Colors.white, size: 26),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              page['label'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 18, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
