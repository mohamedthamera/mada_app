import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import '../home_providers.dart';

class HomeBanner extends ConsumerStatefulWidget {
  const HomeBanner({super.key});

  @override
  ConsumerState<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends ConsumerState<HomeBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < count - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Start auto scroll once we have data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_timer == null || !_timer!.isActive) {
            _startAutoScroll(banners.length);
          }
        });

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final hasVideo =
                      (banner.videoUrl != null && banner.videoUrl!.isNotEmpty);
                  if (hasVideo) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: _VideoBanner(url: banner.videoUrl!),
                    );
                  } else {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        image: DecorationImage(
                          image: NetworkImage(banner.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _VideoBanner extends StatefulWidget {
  const _VideoBanner({required this.url});
  final String url;

  @override
  State<_VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<_VideoBanner> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      developer.log('Initializing video banner: ${widget.url}', name: 'HomeBanner');
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..setVolume(0.0)
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
              _hasError = false;
            });
            _controller?.play();
            developer.log('Video initialized and playing', name: 'HomeBanner');
          }
        }).catchError((error, stack) {
          developer.log('Video initialize error: $error', name: 'HomeBanner', error: error, stackTrace: stack);
          if (mounted) {
            setState(() {
              _initialized = false;
              _hasError = true;
            });
          }
        });
    } catch (e) {
      developer.log('Video controller exception: $e', name: 'HomeBanner', error: e);
      if (mounted) {
        setState(() {
          _initialized = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey),
              SizedBox(height: 8),
              Text('فشل تحميل الفيديو', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final aspect = _controller!.value.aspectRatio == 0
        ? 16 / 9
        : _controller!.value.aspectRatio;
    
    return Container(
      color: Colors.black,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AspectRatio(
          aspectRatio: aspect,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
