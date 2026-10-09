import 'package:port/shared/theme/app_style.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:port/features/stories/presentation/story_text_content.dart';
import 'news_story_content.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryScreen extends StatefulWidget {
  final List<Map<String, String>> stories;
  final int initialIndex;

  const StoryScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  double _progress = 0.0;
  Timer? _progressTimer;
  bool _appActive = true;
  bool _openingLink = false;

  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  late AnimationController _blurAnimationController;
  late Animation<double> _blurAnimation;

  late AnimationController _popOutAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.linear,
      ),
    );

    _progressAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _progress = _progressAnimation.value;
        });
      }
    });

    _blurAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _blurAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _blurAnimation.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _popOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _popOutAnimationController,
        curve: Curves.easeInBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _popOutAnimationController, curve: Curves.easeIn),
    );

    _loadStory();
  }

  void _loadStory() {
    final story = widget.stories[_currentIndex];
    _disposeVideoControllers();
    _resetProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentIndex + 1 >= widget.stories.length) return;
      final next = widget.stories[_currentIndex + 1];
      final imageUrl = next['type'] == 'news' ? next['imageUrl'] : next['url'];
      if ((next['type'] == 'image' || next['type'] == 'news') &&
          (imageUrl ?? '').isNotEmpty) {
        precacheImage(
          ResizeImage(CachedNetworkImageProvider(imageUrl!), width: 1080),
          context,
          onError: (error, stack) {},
        );
      }
    });

    if (story['type'] == 'video') {
      if (_isYouTubeUrl(story['url'] ?? '')) {
        _initializeYouTubePlayer(story['url']!);
      } else {
        _initializeVideoPlayer(story['url']!);
      }
    } else {
      // For both image and text stories, use timer
      _startImageTimer();
    }
  }

  void _resetProgress() {
    _progressAnimationController.reset();
    setState(() {
      _progress = 0.0;
    });
  }

  void _updateProgress(double newProgress) {
    if (mounted) {
      _progressAnimationController.animateTo(newProgress.clamp(0.0, 1.0));
    }
  }

  bool _isYouTubeUrl(String url) {
    return YoutubePlayer.convertUrlToId(url) != null;
  }

  void _initializeYouTubePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _youtubeController?.dispose();

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: true,
          controlsVisibleAtStart: false,
          hideControls: true,
          hideThumbnail: true,
          showLiveFullscreenButton: false,
          useHybridComposition: true,
          forceHD: false,
          enableCaption: false,
          captionLanguage: 'en',
          loop: false,
        ),
      );

      _youtubeController!.addListener(_youtubePlayerListener);
      _startYouTubeProgress();
    }
  }

  void _youtubePlayerListener() {
    if (_youtubeController == null || !_youtubeController!.value.isReady) {
      return;
    }

    final playerState = _youtubeController!.value.playerState;

    if (playerState == PlayerState.ended) {
      _youtubeController!.removeListener(_youtubePlayerListener);
      Future.microtask(() {
        if (mounted) {
          _onStoryComplete();
        }
      });
    }
  }

  void _initializeVideoPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize()
          .then((_) {
            _videoController!.play();
            _startVideoProgress();
          })
          .catchError((error) {
            debugPrint('Error loading video: $error');
          });
  }

  void _startImageTimer() {
    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final increment = 0.05 / 10;
      final newProgress = _progress + increment;

      _updateProgress(newProgress);

      if (newProgress >= 1.0) {
        _onStoryComplete();
        timer.cancel();
      }
    });
  }

  void _startYouTubeProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_youtubeController != null && _youtubeController!.value.isReady) {
        final duration = _youtubeController!.metadata.duration.inMilliseconds;
        final position = _youtubeController!.value.position.inMilliseconds;
        final newProgress = duration > 0 ? position / duration : 0.0;

        _updateProgress(newProgress);

        if (newProgress >= 0.98) {
          _onStoryComplete();
          timer.cancel();
        }
      }
    });
  }

  void _startVideoProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final duration = _videoController!.value.duration.inMilliseconds;
        final position = _videoController!.value.position.inMilliseconds;
        final newProgress = duration > 0 ? position / duration : 0.0;

        _updateProgress(newProgress);

        if (newProgress >= 1.0) {
          _onStoryComplete();
          timer.cancel();
        }
      }
    });
  }

  void _pauseProgress() {
    _progressTimer?.cancel();
    _progressAnimationController.stop();
  }

  void _resumeProgress() {
    if (!_appActive || _openingLink) return;
    final story = widget.stories[_currentIndex];
    if (story['type'] == 'video') {
      if (_isYouTubeUrl(story['url'] ?? '')) {
        _startYouTubeProgress();
      } else {
        _startVideoProgress();
      }
    } else {
      _startImageTimer();
    }
  }

  void _onStoryComplete() {
    _progressTimer?.cancel();

    if (_currentIndex >= widget.stories.length - 1) {
      _popOutAnimationController.forward().then((_) {
        Navigator.pop(context);
      });
      return;
    }

    setState(() {});

    _blurAnimationController.forward().then((_) {
      setState(() {
        _currentIndex++;
      });

      _pageController.nextPage(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );

      _loadStory();

      Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          _blurAnimationController.reverse().then((_) {
            setState(() {});
          });
        }
      });
    });
  }

  void _disposeVideoControllers() {
    if (_youtubeController != null) {
      _youtubeController!.removeListener(_youtubePlayerListener);
      _youtubeController!.dispose();
      _youtubeController = null;
    }

    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }

    _progressTimer?.cancel();
  }

  Future<void> _openStoryLink(String? url) async {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null ||
        !['http', 'https', 'mailto', 'tel'].contains(uri.scheme)) {
      return;
    }
    _openingLink = true;
    _pauseProgress();
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t open this link.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t open this link.')),
        );
      }
    } finally {
      _openingLink = false;
      if (mounted) _resumeProgress();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _videoController?.play();
      _youtubeController?.play();
      _resumeProgress();
    } else {
      _videoController?.pause();
      _youtubeController?.pause();
      _pauseProgress();
    }
  }

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
          Color.alphaBlend(
            baseColor.withValues(alpha: .26),
            AppStyle.background,
          ),
          Color.alphaBlend(
            baseColor.withValues(alpha: .12),
            AppStyle.background,
          ),
          AppStyle.background,
        ];
      } catch (e) {
        debugPrint('Operation failed: $e');
      }
    }

    final hash = (story['text'] ?? '').hashCode.abs();
    final accent = AppStyle.highlights[hash % AppStyle.highlights.length];
    return [
      Color.alphaBlend(accent.withValues(alpha: .22), AppStyle.background),
      AppStyle.cover,
      AppStyle.background,
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeVideoControllers();
    _progressAnimationController.dispose();
    _blurAnimationController.dispose();
    _popOutAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _popOutAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: GestureDetector(
                onLongPress: () {
                  setState(() {
                    _videoController?.pause();
                    _youtubeController?.pause();
                    _pauseProgress();
                  });
                },
                onLongPressUp: () {
                  setState(() {
                    _videoController?.play();
                    _youtubeController?.play();
                    _resumeProgress();
                  });
                },
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.localPosition.dx < screenWidth / 2) {
                    if (_currentIndex > 0) {
                      setState(() {});

                      _blurAnimationController.forward().then((_) {
                        setState(() {
                          _currentIndex--;
                        });

                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeInOut,
                        );

                        _loadStory();

                        Timer(const Duration(milliseconds: 150), () {
                          if (mounted) {
                            _blurAnimationController.reverse().then((_) {
                              setState(() {});
                            });
                          }
                        });
                      });
                    }
                  } else {
                    _onStoryComplete();
                  }
                },
                child: Stack(
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _blurAnimation.value,
                        sigmaY: _blurAnimation.value,
                      ),
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.stories.length,
                        itemBuilder: (context, index) {
                          final story = widget.stories[index];

                          if (story['type'] == 'news') {
                            return NewsStoryContent(
                              story: story,
                              onOpenSource: () =>
                                  _openStoryLink(story['sourceUrl']),
                            );
                          } else if (story['type'] == 'text') {
                            final List<Color> gradientColors =
                                _getTextStoryGradient(story);
                            final String text = story['text'] ?? '';

                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: gradientColors,
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.topRight,
                                    radius: 1.2,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: SafeArea(
                                  child: StoryTextContent(
                                    text: text,
                                    title: story['title'] ?? '',
                                    seed: text.hashCode ^ index,
                                    patternVariant: index,
                                    onTapLink: (_, url, _) =>
                                        _openStoryLink(url),
                                  ),
                                ),
                              ),
                            );
                          } else if (story['type'] == 'image') {
                            return Padding(
                              padding: story['kind'] == 'meme'
                                  ? const EdgeInsets.fromLTRB(12, 60, 12, 220)
                                  : EdgeInsets.zero,
                              child: CachedNetworkImage(
                                imageUrl: story['url'] ?? '',
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                ),
                                memCacheWidth: 1080,
                                memCacheHeight: null,
                                fadeInDuration: const Duration(
                                  milliseconds: 100,
                                ),
                              ),
                            );
                          } else if (_isYouTubeUrl(story['url'] ?? '')) {
                            return _youtubeController != null
                                ? ClipRect(
                                    child: YoutubePlayerBuilder(
                                      player: YoutubePlayer(
                                        controller: _youtubeController!,
                                        showVideoProgressIndicator: false,
                                        progressIndicatorColor:
                                            Colors.transparent,
                                        topActions: const [],
                                        bottomActions: const [],
                                      ),
                                      builder: (context, player) {
                                        return player;
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  );
                          } else if (_videoController != null &&
                              _videoController!.value.isInitialized) {
                            return AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    if (widget.stories[_currentIndex]['kind'] == 'meme')
                      Positioned(
                        bottom: 76,
                        left: 20,
                        right: 20,
                        child: SafeArea(
                          top: false,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xE6181818),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.stories[_currentIndex]['title'] ??
                                        '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openStoryLink(
                                      widget
                                          .stories[_currentIndex]['sourceUrl'],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        '${widget.stories[_currentIndex]['source']} · '
                                        '${widget.stories[_currentIndex]['author']} · View post ↗',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF9CCAF1),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 50,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: List.generate(
                          widget.stories.length,
                          (index) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2.0,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 50),
                                child: LinearProgressIndicator(
                                  value: index < _currentIndex
                                      ? 1.0
                                      : index == _currentIndex
                                      ? _progress
                                      : 0.0,
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.5,
                                  ),
                                  color: Colors.white,
                                  minHeight: 3.0,
                                ),
                              ),
                            ),
                          ),
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
}
