import 'package:flutter/material.dart';
import 'package:port/config.dart';
import 'package:port/forums/stories_widget.dart';
import 'package:port/pages/club/club_detail_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:line_icons/line_icons.dart';
import 'club_model.dart';

class ClubsPage extends StatefulWidget {
  @override
  _ClubsPageState createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  late Future<List<Club>> _clubsFuture;

  @override
  void initState() {
    super.initState();
    _clubsFuture = fetchClubs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "COMMUNITIES",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'ProductSans',
            letterSpacing: 4,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: FutureBuilder<List<Club>>(
        future: _clubsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final clubs = snapshot.data ?? [];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Enables body scrolling
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: StoriesWidget(stories: storyUrls),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shrinkWrap:
                      true, // Important for scrolling inside SingleChildScrollView
                  physics:
                      const NeverScrollableScrollPhysics(), // Disables internal ListView scrolling
                  itemCount: clubs.length,
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClubDetailPage(club: club),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Banner image at top
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.network(
                                club.bannerUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      club.logoUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Club Name and Group
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          club.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'ProductSans',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(LineIcons.users,
                                                size: 16,
                                                color: Colors.white70),
                                            const SizedBox(width: 6),
                                            Text(
                                              club.clubGroup.isNotEmpty
                                                  ? club.clubGroup
                                                  : "Uncategorized",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Share Icon only
                                  IconButton(
                                    icon: const Icon(LineIcons.share,
                                        color: Colors.white),
                                    onPressed: () {
                                      final link =
                                          "https://aca-web-c0e77.web.app/club/${club.id}";
                                      Share.share(
                                          "Check out this club: ${club.name}\n$link");
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 95),
              ],
            ),
          );
        },
      ),
    );
  }
}
