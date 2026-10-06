import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
    AppConfiguration.current.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    AppConfiguration.current.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          "About",
          style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
              letterSpacing: 3),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: const AppBarDivider(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDeveloperCard(),
              const SizedBox(height: 20),
              _buildMaintainerCard(),
              const SizedBox(height: 20),
              _buildAcknowledgmentsSection(),
              const SizedBox(height: 20),
              _buildWhatsAppSection(),
              const SizedBox(height: 20),
              _buildContributorsDropdown(),
              const SizedBox(height: 20),
              _buildInfoCard(
                  title: "About the App",
                  content:
                      "This app has been a significant part of my journey, taking 4 months to develop, including 2 months of full-time effort.\n\nAs a second-year student, I had to learn a lot along the way, and making a production-ready app was a challenging yet rewarding experience.\n\nThe app is entirely free, and setting everything up was undoubtedly difficult. It consists of over 13,000 lines of code, so I apologize in advance if there are any issues or bugs.\n\nPlease feel free to report any issues either in the group or through my social channels, and I will address them as quickly as possible.\n\nThis app would not have been possible without the contributors who provided the notes, especially Codex Crew—I am immensely grateful for their support.\n\nI hope you enjoy using this app\n(RIP my third semesters lol!)"),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return _buildGlassBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 60,
            backgroundImage: AssetImage('assets/images/me.jpg'),
          ),
          const SizedBox(height: 10),
          const Text(
            "Developed by",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pritam Acharya",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "16th CSE ( 2023-27 )",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon('assets/images/insta.png',
                  'https://www.instagram.com/pritam.ach/'),
              const SizedBox(width: 26),
              _buildSocialIcon('assets/images/link.png',
                  'https://www.linkedin.com/in/pritamacharya/'),
              const SizedBox(width: 26),
              _buildSocialIcon('assets/images/yt.png',
                  'https://www.youtube.com/@Pritam-Ach'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMaintainerCard() {
    return _buildGlassBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/swayanshu.png'),
          ),
          const SizedBox(height: 10),
          const Text(
            "Maintained by",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Swayanshu Sarthak Sadangi",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "17th CSE ( 2024-28 )",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final url = Uri.parse('https://swynx.dev');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              "swynx.dev",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAcknowledgmentsSection() {
    return _buildGlassBox(
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/codex.jpeg',
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Special Thanks to Codex Crew!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your support made this app a reality!",
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppSection() {
    return _buildGlassBox(
      child: Column(
        children: [
          const SizedBox(height: 6),
          Image.asset('assets/images/whats.png', height: 85, width: 85),
          const SizedBox(height: 18),
          const Text(
            "Join Our WhatsApp Group",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Stay updated with the latest features and announcements!",
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.link, color: Colors.black),
            label: const Text(
              "Join Now",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              _openUrl("https://chat.whatsapp.com/DDuQv0UAkKpBmXB29fBjLw");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return _buildGlassBox(
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsDropdown() {
    return _buildGlassBox(
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: const Text(
          "Contributors",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: contributors.map((contributor) {
          return ListTile(
            title: Text(
              contributor['name']!,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            onTap: () {
              _openUrl(contributor['url']!);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          "© 2024 Alcademy. All rights reserved.",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildGlassBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSocialIcon(String assetPath, String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Image.asset(assetPath, height: 22, width: 22),
    );
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
