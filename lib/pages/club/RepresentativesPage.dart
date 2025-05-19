import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Add this package

class ClubRepresentativesPage extends StatefulWidget {
  final String clubId;

  const ClubRepresentativesPage({super.key, required this.clubId});

  @override
  State<ClubRepresentativesPage> createState() =>
      _ClubRepresentativesPageState();
}

class _ClubRepresentativesPageState extends State<ClubRepresentativesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  String clubName = "";
  List<Map<String, dynamic>> representatives = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchClubData();
  }

  Future<void> fetchClubData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final clubResponse = await supabase
          .from('clubs')
          .select('name')
          .eq('id', widget.clubId)
          .maybeSingle();

      final repsResponse = await supabase
          .from('club_representatives')
          .select('*')
          .eq('club_id', widget.clubId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          clubName = clubResponse?['name'] ?? "Club";
          representatives = List<Map<String, dynamic>>.from(repsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Failed to load representatives: ${e.toString()}";
        });
      }
    }
  }

  void _openSocialLink(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text('Representatives',
          style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
              letterSpacing: 3),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_hasError || representatives.isEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: fetchClubData,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2), // Subtle separator
            height: 1,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1D1E),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_hasError) {
      return _buildErrorView();
    }

    if (representatives.isEmpty) {
      return const Center(
        child: Text(
          "No representatives found.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.separated(
          itemCount: representatives.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rep = representatives[index];
            final Map<String, dynamic> socialMap = rep['socials'] ?? {};
            final List<Map<String, String>> socialLinks = socialMap.entries
                .map((entry) =>
                    {"platform": entry.key, "url": entry.value.toString()})
                .toList();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      rep['profile_url'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(LineIcons.user,
                              color: Colors.white70, size: 30),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rep['name'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rep['designation'],
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        if (socialLinks.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: socialLinks.map((social) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => _openSocialLink(social['url']!),
                                  child: Icon(
                                    _getSocialIcon(social['platform']!),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Modern pulse loading animation
          SpinKitPulse(
            color: Colors.purpleAccent,
            size: 50.0,
          ),
          const SizedBox(height: 20),
          Text(
            "Loading ${clubName.isEmpty ? '' : '$clubName '}Representatives...",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              "Failed to load representatives",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchClubData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.purpleAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return LineIcons.linkedin;
      case 'twitter':
        return LineIcons.twitter;
      case 'github':
        return LineIcons.github;
      case 'instagram':
        return LineIcons.instagram;
      default:
        return LineIcons.link;
    }
  }
}
