import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'random_bg.dart';

class NewsStoryContent extends StatelessWidget {
  final Map<String, String> story;
  final VoidCallback onOpenSource;
  final Widget? imageOverride;

  const NewsStoryContent({
    super.key,
    required this.story,
    required this.onOpenSource,
    this.imageOverride,
  });

  @override
  Widget build(BuildContext context) => StoryBackdrop(
    seed: storyPatternSeed(story['id'] ?? story['title'] ?? ''),
    child: SafeArea(
      child: Padding(
        // Reserve breathing room above the progress indicators at bottom: 50.
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.newspaper_rounded,
                  color: AppStyle.text,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['source'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppStyle.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        story['category'] == 'india' ? 'INDIA' : 'TECHNOLOGY',
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppStyle.muted,
                          fontSize: 10,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('news-story-source-button'),
                  tooltip: 'Read full story',
                  onPressed: onOpenSource,
                  icon: const Icon(Icons.north_east_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: AppStyle.text,
                    backgroundColor: Colors.white.withValues(alpha: .08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scaler = MediaQuery.textScalerOf(context);
                  final direction = Directionality.of(context);
                  TextPainter measure(String text, TextStyle style) =>
                      TextPainter(
                        text: TextSpan(text: text, style: style),
                        textDirection: direction,
                        textScaler: scaler,
                      )..layout(maxWidth: constraints.maxWidth);
                  const descriptionStyle = TextStyle(
                    color: Color(0xC7F2F2F2),
                    fontSize: 16,
                    height: 1.45,
                    fontFamily: 'ProductSans',
                  );
                  const headlineStyle = TextStyle(
                    color: AppStyle.text,
                    fontFamily: 'ProductSans',
                    fontSize: 26,
                    height: 1.18,
                    letterSpacing: -.5,
                    fontWeight: FontWeight.bold,
                  );
                  final description = measure(
                    story['description']!,
                    descriptionStyle,
                  );
                  final descriptionHeight = description.height;
                  description.dispose();
                  var fontSize = 26.0;
                  var titleHeight = 0.0;
                  while (true) {
                    final title = measure(
                      story['title']!,
                      headlineStyle.copyWith(fontSize: fontSize),
                    );
                    titleHeight = title.height;
                    title.dispose();
                    if (fontSize <= 20 ||
                        titleHeight + descriptionHeight + 112 <=
                            constraints.maxHeight) {
                      break;
                    }
                    fontSize -= 2;
                  }
                  // Use space from the photo before reducing any reading text.
                  titleHeight = titleHeight.clamp(
                    0,
                    constraints.maxHeight * .45,
                  );
                  final imageHeight =
                      (constraints.maxHeight -
                              titleHeight -
                              descriptionHeight -
                              32)
                          .clamp(
                            80,
                            (constraints.maxHeight * .42).clamp(80, 260),
                          );
                  final bodyHeight =
                      constraints.maxHeight - imageHeight - titleHeight - 32;
                  final line = measure('Ag', descriptionStyle);
                  final descriptionLines = (bodyHeight / line.height)
                      .floor()
                      .clamp(1, 30);
                  line.dispose();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        key: const Key('news-story-image'),
                        height: imageHeight.toDouble(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child:
                              imageOverride ??
                              CachedNetworkImage(
                                imageUrl: story['imageUrl']!,
                                fit: BoxFit.cover,
                                memCacheWidth: 1080,
                                placeholder: (_, _) => const ColoredBox(
                                  color: AppStyle.surface,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => const ColoredBox(
                                  color: AppStyle.surface,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppStyle.muted,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: titleHeight,
                              child: AutoSizeText(
                                story['title']!,
                                key: const Key('news-story-title'),
                                textAlign: TextAlign.center,
                                minFontSize: 20,
                                maxFontSize: 26,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                stepGranularity: .5,
                                style: headlineStyle.copyWith(
                                  fontSize: fontSize,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Flexible(
                              child: Text(
                                story['description']!,
                                key: const Key('news-story-description'),
                                textAlign: TextAlign.center,
                                maxLines: descriptionLines,
                                overflow: TextOverflow.ellipsis,
                                style: descriptionStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
