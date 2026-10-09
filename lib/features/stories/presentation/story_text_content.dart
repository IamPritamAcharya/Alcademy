import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:port/shared/theme/app_style.dart';
import 'random_bg.dart';

class StoryTextContent extends StatelessWidget {
  final String text;
  final String title;
  final int seed;
  final int? patternVariant;
  final MarkdownTapLinkCallback onTapLink;
  const StoryTextContent({
    super.key,
    required this.text,
    this.title = '',
    required this.seed,
    this.patternVariant,
    required this.onTapLink,
  });

  String get _bodyText {
    if (title.trim().isEmpty) return text;
    final paragraphs = text.trim().split(RegExp(r'\n\s*\n'));
    final first = paragraphs.first
        .replaceAll(RegExp(r'^[#\s]+|[*_]'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .trim();
    if (first.toLowerCase() == title.trim().toLowerCase()) {
      return paragraphs.skip(1).join('\n\n');
    }
    return text;
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: StoryPatternPainter(seed, variant: patternVariant),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 80),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  key: const Key('custom-story-group'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title.trim().isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * .24,
                        ),
                        child: AutoSizeText(
                          title,
                          key: const Key('custom-story-title'),
                          textAlign: TextAlign.center,
                          minFontSize: 8,
                          maxLines: 3,
                          style: const TextStyle(
                            color: AppStyle.text,
                            fontFamily: 'ProductSans',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _markdown(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _markdown(BuildContext context) => MarkdownBody(
    data: _bodyText,
    fitContent: false,
    softLineBreak: true,
    onTapLink: onTapLink,
    sizedImageBuilder: (image) => Text(
      image.alt ?? 'Image',
      style: const TextStyle(color: AppStyle.muted),
    ),
    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: const TextStyle(
        color: AppStyle.text,
        fontSize: 20,
        height: 1.55,
        fontFamily: 'ProductSans',
      ),
      textAlign: WrapAlignment.center,
      h1Align: WrapAlignment.center,
      h2Align: WrapAlignment.center,
      h3Align: WrapAlignment.center,
      h1: const TextStyle(
        color: AppStyle.text,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ),
      h2: const TextStyle(
        color: AppStyle.text,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h3: const TextStyle(
        color: AppStyle.text,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
      a: const TextStyle(
        color: AppStyle.blue,
        decoration: TextDecoration.underline,
        decorationColor: AppStyle.blue,
        fontWeight: FontWeight.w600,
      ),
      blockSpacing: 16,
      listBullet: const TextStyle(
        color: AppStyle.muted,
        fontSize: 18,
        height: 1.55,
      ),
      blockquote: const TextStyle(
        color: AppStyle.text,
        fontSize: 18,
        height: 1.5,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .16),
        border: const Border(left: BorderSide(color: AppStyle.muted, width: 2)),
      ),
      code: const TextStyle(
        fontFamily: 'monospace',
        color: AppStyle.gold,
        fontSize: 16,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppStyle.background.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
