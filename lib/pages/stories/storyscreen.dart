import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class StoryScreen extends StatefulWidget {
  final List<Map<String, String>> stories;
  final int initialIndex;

  const StoryScreen(
      {Key? key, required this.stories, required this.initialIndex})
      : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isPaused = false;
  double _progress = 0.0;
  Timer? _progressTimer;
  bool _isTransitioning = false;

  
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
      duration:
          const Duration(milliseconds: 300), 
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
    if (_youtubeController == null || !_youtubeController!.value.isReady)
      return;

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
        print('Error loading video: $error');
      });
  }

  void _startImageTimer() {
    const duration = Duration(seconds: 10);
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

    
    setState(() {
      _isTransitioning = true;
    });

    
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
            setState(() {
              _isTransitioning = false;
            });
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
                    _isPaused = true;
                    _videoController?.pause();
                    _youtubeController?.pause();
                    _pauseProgress();
                  });
                },
                onLongPressUp: () {
                  setState(() {
                    _isPaused = false;
                    _videoController?.play();
                    _youtubeController?.play();
                    _resumeProgress();
                  });
                },
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.localPosition.dx < screenWidth / 2) {
                    if (_currentIndex > 0) {
                      setState(() {
                        _isTransitioning = true;
                      });

                      
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
                              setState(() {
                                _isTransitioning = false;
                              });
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
                          if (story['type'] == 'image') {
                            return Image.network(
                              story['url'] ?? '',
                              fit: BoxFit.contain,
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
                                    child: CircularProgressIndicator());
                          } else if (_videoController != null &&
                              _videoController!.value.isInitialized) {
                            return AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            );
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
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
