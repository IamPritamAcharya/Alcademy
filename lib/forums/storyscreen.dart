import 'dart:async';
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

class _StoryScreenState extends State<StoryScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isPaused = false;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadStory();
  }

  void _loadStory() {
    final story = widget.stories[_currentIndex];
    _disposeVideoControllers();
    setState(() {
      _progress = 0.0;
    });

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

  bool _isYouTubeUrl(String url) {
    return YoutubePlayer.convertUrlToId(url) != null;
  }

  void _initializeYouTubePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      // Dispose any previous controller safely before creating a new one
      _youtubeController?.dispose();

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: true,
          controlsVisibleAtStart: false,
          hideControls: true,
          loop: false,
        ),
      );

      // Add listener to detect when video ends
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
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _onStoryComplete();
          timer.cancel();
        }
      });
    });
  }

  void _startYouTubeProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_youtubeController != null) {
        final duration = _youtubeController!.metadata.duration.inSeconds;
        final position = _youtubeController!.value.position.inSeconds;
        setState(() {
          _progress = duration > 0 ? position / duration : 0.0;
        });
        if (_progress >= 1.0) {
          _onStoryComplete();
          timer.cancel();
        }
      }
    });
  }

  void _startVideoProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final duration = _videoController!.value.duration.inSeconds;
        final position = _videoController!.value.position.inSeconds;
        setState(() {
          _progress = duration > 0 ? position / duration : 0.0;
        });
        if (_progress >= 1.0) {
          _onStoryComplete();
          timer.cancel();
        }
      }
    });
  }

  void _onStoryComplete() {
    _progressTimer?.cancel();
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory();
    } else {
      Navigator.pop(context); // Exit story view when all stories are done.
    }
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPress: () {
          setState(() {
            _isPaused = true;
            _videoController?.pause();
            _youtubeController?.pause();
            _progressTimer?.cancel();
          });
        },
        onLongPressUp: () {
          setState(() {
            _isPaused = false;
            _videoController?.play();
            _youtubeController?.play();
            _loadStory();
          });
        },
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth / 2) {
            if (_currentIndex > 0) {
              setState(() {
                _currentIndex--;
              });
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _loadStory();
            }
          } else {
            _onStoryComplete();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
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
                      ? YoutubePlayerBuilder(
                          player: YoutubePlayer(
                            controller: _youtubeController!,
                          ),
                          builder: (context, player) {
                            return player;
                          },
                        )
                      : const Center(child: CircularProgressIndicator());
                } else if (_videoController != null &&
                    _videoController!.value.isInitialized) {
                  return AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
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
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: LinearProgressIndicator(
                        value: index < _currentIndex
                            ? 1.0
                            : index == _currentIndex
                                ? _progress
                                : 0.0,
                        backgroundColor: Colors.grey.withOpacity(0.5),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
