import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

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
      {'icon': LineIcons.info, 'route': '/about', 'label': 'About'},
    ];

    return Drawer(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 150,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.transparent,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundImage: userProfileImage != null
                          ? NetworkImage(userProfileImage)
                          : const NetworkImage(
                              'https://cdn-icons-png.flaticon.com/512/4322/4322991.png',
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(page['icon'] as IconData,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  page['label'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
