import 'package:port/shared/widgets/editorial_list_row.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/core/network/refresh_tracker.dart';
import 'package:port/shared/widgets/custom_snackbar.dart';
import 'package:port/features/success_stories/data/success_stories_repository.dart';
import 'package:port/features/success_stories/presentation/story_details_page.dart';

class SuccessStoriesPage extends StatefulWidget {
  const SuccessStoriesPage({super.key});

  @override
  State<SuccessStoriesPage> createState() => _SuccessStoriesPageState();
}

class _SuccessStoriesPageState extends State<SuccessStoriesPage> {
  late Future<List<Map<String, String>>> storiesFuture;

  @override
  void initState() {
    super.initState();
    storiesFuture = _fetchStories();
  }

  Future<List<Map<String, String>>> _fetchStories({
    bool forceRefresh = false,
  }) async {
    return SuccessStoriesRepository.fetchStories(forceRefresh: forceRefresh);
  }

  Future<void> _handleRefresh() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(CustomSnackBar.build(isCooldown: true, context: context));
      return;
    }

    if (mounted) {
      setState(() {
        storiesFuture = _fetchStories(forceRefresh: true);
      });
    }
    await storiesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: const Text(
          'Success Stories',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: -.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppStyle.background,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppStyle.text,
        backgroundColor: AppStyle.background,
        child: FutureBuilder<List<Map<String, String>>>(
          future: storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppStyle.text),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppStyle.text),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No success stories found.',
                  style: TextStyle(color: AppStyle.text),
                ),
              );
            }

            final stories = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: stories.length + 1,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CollectionIntro(
                    title: 'People & paths.',
                    eyebrow: 'AFTER THE CAMPUS',
                    detail: '${stories.length} journeys, in their own words',
                  );
                }
                final story = stories[index - 1];
                return EditorialListRow(
                  number: index,
                  title: story['name'] ?? 'Student story',
                  category: story['company'] ?? 'Student journey',
                  accent: AppStyle.lilac,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      story['image_url'] ?? '',
                      width: 48,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 48,
                        height: 60,
                        child: Icon(
                          Icons.person_outline,
                          color: AppStyle.muted,
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    final name = story['name'];
                    final body = story['body'];
                    if (name == null || body == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load story details.'),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryDetailPage(name: name, body: body),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
