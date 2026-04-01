import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:port/pages/stories/storyscreen.dart';

class StoriesWidget extends StatelessWidget {
  final List<Map<String, String>> stories;
  const StoriesWidget({Key? key, required this.stories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
        child: Row(
          children: [
            for (int index = 0; index < stories.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
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
                  child: StoryCircle(story: stories[index], index: index),
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
  final int index;
  const StoryCircle({Key? key, required this.story, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      child: ClipOval(
        child: story['type'] == 'text'
            ? TextStoryPreview(story: story)
            : story['type'] == 'image'
                ? OptimizedImage(url: story['url']!)
                : YouTubeThumbnail(url: story['url']!),
      ),
    );
  }
}

class TextStoryPreview extends StatelessWidget {
  final Map<String, String> story;
  const TextStoryPreview({Key? key, required this.story}) : super(key: key);

  List<Color> _getTextStoryGradient(Map<String, String> story) {
    final String? bgColor = story['backgroundColor'];
    if (bgColor != null && bgColor.isNotEmpty) {
      try {
        String colorStr = bgColor;
        if (colorStr.startsWith('#')) {
          colorStr = colorStr.replaceFirst('#', '0xFF');
        }
        final Color baseColor = Color(int.parse(colorStr));
        return [
          baseColor,
          baseColor.withOpacity(0.8),
        ];
      } catch (e) {}
    }

    final List<List<Color>> gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
      [const Color(0xFFffecd2), const Color(0xFFfcb69f)],
      [const Color(0xFFd299c2), const Color(0xFFfef9d7)],
      [const Color(0xFF89f7fe), const Color(0xFF66a6ff)],
      [const Color(0xFFfbc2eb), const Color(0xFFa6c1ee)],
    ];

    final int hash = (story['text'] ?? '').hashCode;
    final selectedGradient = gradients[hash.abs() % gradients.length];
    return selectedGradient;
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = _getTextStoryGradient(story);
    final String text = story['text'] ?? '';

    String previewText =
        text.length > 15 ? '${text.substring(0, 15)}...' : text;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 5,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                previewText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptimizedImage extends StatelessWidget {
  final String url;
  const OptimizedImage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: 70,
      height: 70,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.error,
        color: Colors.red,
        size: 30,
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}

class YouTubeThumbnail extends StatelessWidget {
  final String url;
  const YouTubeThumbnail({Key? key, required this.url}) : super(key: key);

  String _extractYouTubeId(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return '';

    if (uri.host.contains('youtube.com')) {
      if (uri.path.startsWith('/shorts/')) {
        return uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
      }
      return uri.queryParameters['v'] ?? '';
    }

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

    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      fit: BoxFit.cover,
      width: 70,
      height: 70,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.red),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}
