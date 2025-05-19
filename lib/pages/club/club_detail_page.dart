import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/pages/club/clubspost.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'club_model.dart';

class ClubDetailPage extends StatefulWidget {
  final Club club;
  const ClubDetailPage({required this.club});

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  final user = Supabase.instance.client.auth.currentUser;
  bool isJoined = false;
  bool loading = false;
  int memberCount = 0;

  @override
  void initState() {
    super.initState();
    memberCount = widget.club.memberCount;
    checkMembership();
    fetchMemberCountFromDB();
  }

  Future<void> checkMembership() async {
    if (user == null) return;
    final res = await Supabase.instance.client
        .from('club_members')
        .select('id')
        .eq('club_id', widget.club.id)
        .eq('user_id', user!.id)
        .maybeSingle();

    if (mounted) {
      setState(() {
        isJoined = res != null;
      });
    }
  }

  Future<void> fetchMemberCountFromDB() async {
    final res = await Supabase.instance.client
        .from('clubs')
        .select('member_count')
        .eq('id', widget.club.id)
        .maybeSingle();

    if (res != null && res['member_count'] != null && mounted) {
      setState(() {
        memberCount = res['member_count'];
      });
    }
  }

  Future<void> toggleMembership() async {
    setState(() => loading = true);
    try {
      if (isJoined) {
        await Supabase.instance.client
            .from('club_members')
            .delete()
            .eq('club_id', widget.club.id)
            .eq('user_id', user!.id);
      } else {
        await Supabase.instance.client.from('club_members').insert({
          'club_id': widget.club.id,
          'user_id': user!.id,
        });
      }
      await checkMembership();
      await fetchMemberCountFromDB();
    } catch (e) {
      print("Membership toggle error: $e");
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260, // Increased height to fit content
            floating: false,
            backgroundColor: const Color(0xFF1A1D1E),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.white24),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.club.bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white70, size: 40),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color.fromARGB(12, 255, 255, 255),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(widget.club.logoUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.club.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$memberCount members',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user != null)
                          ElevatedButton(
                            onPressed: loading ? null : toggleMembership,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isJoined
                                  ? Colors.grey[300]
                                  : Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              loading
                                  ? "Please wait..."
                                  : (isJoined ? "Joined" : "Join"),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10)
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(LineIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(LineIcons.share, color: Colors.white),
                onPressed: () {
                  final link =
                      "https://aca-web-c0e77.web.app/club/${widget.club.id}";
                  Share.share(
                      "Join ${widget.club.name} with $memberCount members!\n$link");
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClubPostsList(clubId: widget.club.id),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class ClubDetailPageFromLink extends StatelessWidget {
  final String clubId;
  const ClubDetailPageFromLink({required this.clubId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Club>>(
      future: fetchClubs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final club = snapshot.data!
            .firstWhere((c) => c.id == clubId, orElse: () => Club.empty());
        if (club.id.isEmpty) {
          return const Scaffold(body: Center(child: Text("Club not found")));
        }
        return ClubDetailPage(club: club);
      },
    );
  }
}
