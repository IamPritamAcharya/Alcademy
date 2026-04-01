import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:port/pages/stories/random_bg.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryScreen extends StatefulWidget {
  final List<Map<String, String>> stories;
  final int initialIndex;

  const StoryScreen(
      {super.key, required this.stories, required this.initialIndex});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  double _progress = 0.0;
  Timer? _progressTimer;

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
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.linear,
    ));

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

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _blurAnimationController,
      curve: Curves.easeInOut,
    ));

    _blurAnimation.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _popOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _popOutAnimationController,
      curve: Curves.easeInBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _popOutAnimationController,
      curve: Curves.easeIn,
    ));

    _loadStory();
  }

  void _loadStory() {
    final story = widget.stories[_currentIndex];
    _disposeVideoControllers();
    _resetProgress();

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
      _progressAnimationController.animateTo(
        newProgress.clamp(0.0, 1.0),
      );
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
    _videoController = VideoPlayerController.network(url)
      ..initialize().then((_) {
        _videoController!.play();
        _startVideoProgress();
      }).catchError((error) {
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

  List<TextSpan> _parseTextWithLinks(String text) {
    final List<TextSpan> spans = [];
    final RegExp urlRegex = RegExp(
      r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final Match match in urlRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ));
      }

      String url = match.group(0)!;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      spans.add(TextSpan(
        text: match.group(0)!,
        style: const TextStyle(
          color: Color(0xFF00D4FF),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF00D4FF),
          decorationThickness: 2,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            try {
              final Uri uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } catch (e) {
              debugPrint('Error launching URL: $e');
            }
          },
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
      ));
    }

    return spans;
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
          baseColor,
          baseColor.withOpacity(0.8),
          baseColor.withOpacity(0.6),
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
    return [
      selectedGradient[0],
      selectedGradient[1],
      selectedGradient[0].withOpacity(0.8),
    ];
  }

  @override
  void dispose() {
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

                          if (story['type'] == 'text') {
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
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: SafeArea(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: getRandomPainter(index),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32.0,
                                          vertical: 40.0,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(24.0),
                                              child: Center(
                                                child: RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    children:
                                                        _parseTextWithLinks(
                                                            text),
                                                    style: const TextStyle(
                                                      fontFamily: 'ProductSans',
                                                      height: 1.4,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (story['type'] == 'image') {
                            return CachedNetworkImage(
                              imageUrl: story['url'] ?? '',
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
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
                              memCacheWidth: null,
                              memCacheHeight: null,
                              fadeInDuration: const Duration(milliseconds: 100),
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
                                          Colors.white),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          }
                        },
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 50),
                                child: LinearProgressIndicator(
                                  value: index < _currentIndex
                                      ? 1.0
                                      : index == _currentIndex
                                          ? _progress
                                          : 0.0,
                                  backgroundColor: Colors.grey.withOpacity(0.5),
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
