import 'package:flutter/material.dart';
import 'package:port/forums/storyscreen.dart';

class StoriesWidget extends StatelessWidget {
  final List<Map<String, String>> stories;

  const StoriesWidget({Key? key, required this.stories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            for (int index = 0; index < stories.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  left: index == 0
                      ? 16.0
                      : 8.0, // Extra padding for the first item
                  right: 8.0,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryScreen(
                          stories: stories,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: StoryCircle(story: stories[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StoryCircle extends StatelessWidget {
  final Map<String, String> story;

  const StoryCircle({Key? key, required this.story}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 35,
      child: ClipOval(
        child: story['type'] == 'image'
            ? Image.network(
                story['url']!,
                fit: BoxFit.cover,
                height: 70,
                width: 70,
              )
            : YouTubeThumbnail(url: story['url']!),
      ),
    );
  }
}

class YouTubeThumbnail extends StatelessWidget {
  final String url;

  const YouTubeThumbnail({Key? key, required this.url}) : super(key: key);

  /// Extracts the YouTube video ID from the given URL, including `shorts` URLs.
  String _extractYouTubeId(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return '';

    // Handle standard YouTube URLs
    if (uri.host.contains('youtube.com')) {
      if (uri.path.startsWith('/shorts/')) {
        // Extract video ID from shorts URL
        return uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
      }
      // Extract video ID from standard YouTube video URL
      return uri.queryParameters['v'] ?? '';
    }

    // Handle youtu.be URLs
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractYouTubeId(url);
    if (videoId.isEmpty) {
      return const Icon(Icons.error, color: Colors.red);
    }
    final thumbnailUrl =
        'https://img.youtube.com/vi/$videoId/0.jpg'; // Fetch the thumbnail

    return Image.network(
      thumbnailUrl,
      fit: BoxFit.cover,
      height: 70,
      width: 70,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}
