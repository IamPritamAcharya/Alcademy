import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:port/features/stories/presentation/story_screen.dart';
import 'random_bg.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/home_pressable.dart';

class StoriesWidget extends StatelessWidget {
  final List<Map<String, String>> stories;
  const StoriesWidget({super.key, required this.stories});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 148,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      itemCount: stories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final story = stories[index];
        final isText = story['type'] == 'text';
        final isImage = story['type'] == 'image' || story['type'] == 'news';
        final tint = AppStyle.highlights[index % AppStyle.highlights.length];
        final label = story['kind'] == 'news'
            ? 'News'
            : isText
            ? 'A quick read'
            : isImage
            ? 'In pictures'
            : 'Watch this';
        return SizedBox(
          width: 116,
          child: Semantics(
            label: 'Story ${index + 1}: ${story['title'] ?? label}',
            button: true,
            child: HomePressable(
              entranceOrder: index,
              color: AppStyle.surface,
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: tint.withValues(alpha: .25)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StoryScreen(stories: stories, initialIndex: index),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isText)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.alphaBlend(
                              AppStyle
                                  .highlights[storyPatternSeed(
                                        story['title'] ?? story['text'] ?? '',
                                      ) %
                                      AppStyle.highlights.length]
                                  .withValues(alpha: .24),
                              AppStyle.background,
                            ),
                            AppStyle.background,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 34, 12, 34),
                        child: Text(
                          story['title'] ?? story['text'] ?? '',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppStyle.text,
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (isImage)
                    OptimizedImage(
                      url:
                          story['imageUrl'] ??
                          story['thumbnail'] ??
                          story['url'] ??
                          '',
                    )
                  else
                    YouTubeThumbnail(url: story['url'] ?? ''),
                  if (!isText)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x55000000),
                            Colors.transparent,
                            Color(0xDD15151E),
                          ],
                          stops: [0, .35, 1],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Icon(
                          story['type'] == 'news'
                              ? Icons.newspaper_rounded
                              : isText
                              ? Icons.format_quote_rounded
                              : isImage
                              ? Icons.photo_outlined
                              : Icons.play_circle_outline_rounded,
                          color: isText ? tint : Colors.white,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppStyle.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class OptimizedImage extends StatelessWidget {
  final String url;
  const OptimizedImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: 348,
      maxWidthDiskCache: 348,
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
          const Icon(Icons.error, color: Colors.red, size: 30),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}

class YouTubeThumbnail extends StatelessWidget {
  final String url;
  const YouTubeThumbnail({super.key, required this.url});

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
