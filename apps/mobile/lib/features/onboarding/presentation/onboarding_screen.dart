import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:shared/shared.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: [
                    _IntroVideoPage(onFinished: () => context.go('/home')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroVideoPage extends StatelessWidget {
  const _IntroVideoPage({required this.onFinished});
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return _IntroVideo(fullScreen: true, onFinished: onFinished);
  }
}

class _IntroVideo extends StatefulWidget {
  const _IntroVideo({this.fullScreen = false, this.onFinished});
  final bool fullScreen;
  final VoidCallback? onFinished;

  @override
  State<_IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends State<_IntroVideo> {
  bool _failed = false;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      await _controller.initialize();
      final invalidSize =
          _controller.value.size.isEmpty ||
          _controller.value.size.width == 0 ||
          _controller.value.size.height == 0;
      if (!invalidSize) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        bool notified = false;
        _controller.addListener(() {
          if (notified) return;
          final v = _controller.value;
          final dur = v.duration;
          final pos = v.position;
          if (v.isInitialized &&
              !v.isLooping &&
              dur > Duration.zero &&
              pos >= dur - const Duration(milliseconds: 200)) {
            notified = true;
            widget.onFinished?.call();
          }
        });
        return;
      } else {
        await _controller.dispose();
        throw Exception('Invalid video size for asset intro.mp4');
      }
    } catch (e) {
      debugPrint(
        'Intro video asset failed: $e. Falling back to network sample.',
      );
    }

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        ),
      );
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      _controller.play();
      bool notified = false;
      _controller.addListener(() {
        if (notified) return;
        final v = _controller.value;
        final dur = v.duration;
        final pos = v.position;
        if (v.isInitialized &&
            !v.isLooping &&
            dur > Duration.zero &&
            pos >= dur - const Duration(milliseconds: 200)) {
          notified = true;
          widget.onFinished?.call();
        }
      });
    } catch (e) {
      debugPrint('Network fallback video failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || !_controller.value.isInitialized) {
      return Container(color: Colors.black26);
    }
    if (widget.fullScreen) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      );
    }
  }
}
