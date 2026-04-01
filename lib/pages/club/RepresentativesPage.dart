import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/utils/refresh_tracker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const Duration _cacheExpiry = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _initRefreshTracker();
    fetchClubData();
  }

  @override
  void dispose() {
    RefreshTracker.dispose();
    super.dispose();
  }

  Future<void> _initRefreshTracker() async {
    await RefreshTracker.init();
  }

  Future<void> _saveCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'club_${widget.clubId}_data';
      final cacheTimeKey = 'club_${widget.clubId}_cache_time';

      final cacheData = {
        'clubName': clubName,
        'representatives': representatives,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      await prefs.setString(cacheTimeKey, DateTime.now().toIso8601String());

      debugPrint(
          'Cache saved for club ${widget.clubId} with ${representatives.length} representatives');
    } catch (e) {
      debugPrint('Failed to save cache: $e');
    }
  }

  Future<bool> _loadCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'club_${widget.clubId}_data';
      final cacheTimeKey = 'club_${widget.clubId}_cache_time';

      final cachedData = prefs.getString(cacheKey);
      final cacheTimeStr = prefs.getString(cacheTimeKey);

      if (cachedData != null && cacheTimeStr != null) {
        final cacheTime = DateTime.parse(cacheTimeStr);
        final cacheAge = DateTime.now().difference(cacheTime);

        if (cacheAge < _cacheExpiry) {
          final data = jsonDecode(cachedData);

          if (mounted) {
            setState(() {
              clubName = data['clubName'] ?? "";
              representatives = List<Map<String, dynamic>>.from(
                  data['representatives'] ?? []);
              _isLoading = false;
              _hasError = false;
            });
          }

          debugPrint(
              'Cache loaded for club ${widget.clubId}, age: ${cacheAge.inMinutes}min');
          return true;
        } else {
          debugPrint(
              'Cache expired for club ${widget.clubId}, age: ${cacheAge.inMinutes}min');
        }
      }
    } catch (e) {
      debugPrint('Failed to load cache: $e');
    }
    return false;
  }

  Future<void> fetchClubData({bool forceRefresh = false}) async {
    try {
      debugPrint(
          'Fetching data for club ${widget.clubId}, forceRefresh: $forceRefresh');

      if (!forceRefresh) {
        final cacheLoaded = await _loadCacheData();
        if (cacheLoaded) {
          return;
        }
      }

      if (forceRefresh) {
        final canRefresh = await RefreshTracker.incrementRefreshCount();
        debugPrint(
            'RefreshTracker check - canRefresh: $canRefresh, count: ${RefreshTracker.refreshCount}');

        if (!canRefresh) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Refresh limit reached. Please wait before refreshing again.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

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

        debugPrint(
            'Fetched ${representatives.length} representatives from API');

        await _saveCacheData();
      }
    } catch (e) {
      debugPrint('Error fetching club data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Failed to load representatives: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    debugPrint('Pull-to-refresh triggered');
    await fetchClubData(forceRefresh: true);
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
        title: const Text(
          'Representatives',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1D1E),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && representatives.isEmpty) {
      return _buildLoadingIndicator();
    }

    if (_hasError && representatives.isEmpty) {
      return _buildErrorView();
    }

    if (representatives.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: Colors.white70,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No representatives found.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Pull down to refresh",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
                                      onTap: () =>
                                          _openSocialLink(social['url']!),
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
              },
            ),
          ),
          if (_isLoading && representatives.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF1A1D1E).withOpacity(0.9),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Refreshing...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitPulse(
            color: Colors.white,
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
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Padding(
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
                const SizedBox(height: 16),
                const Text(
                  "Pull down to refresh or tap retry",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => fetchClubData(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
