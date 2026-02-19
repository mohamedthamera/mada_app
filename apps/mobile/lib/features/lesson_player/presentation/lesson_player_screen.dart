import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/widgets.dart';
import '../../progress/data/progress_repository.dart';
import '../../subscription/presentation/subscription_providers.dart';
import '../../courses/presentation/lesson_providers.dart';
import '../../../app/di.dart';
import 'text_file_viewer_screen.dart';

class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
    required this.courseId,
  });

  final String lessonId;
  final String courseId;

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  VideoPlayerController? _controller;
  String? _currentUrl;
  double _volume = 1.0;

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressRepo = ref.read(progressRepositoryProvider);
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';
    final hasSubAsync = ref.watch(hasActiveSubscriptionProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: hasSubAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        // عند فشل التحقق من الاشتراك نعتبر المستخدم غير مشترك ونسمح بفتح الدروس المجانية
        error: (_, __) => _buildContentForUnsubscribed(ref, progressRepo, userId),
        data: (hasSub) {
          final lessonAsync = ref.watch(lessonProvider(widget.lessonId));

          // غير مشترك: نتحقق إن كان الدرس مجانياً فنعرض المشغّل، وإلا نعرض القفل
          if (!hasSub) {
            return lessonAsync.when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Scaffold(
                appBar: AppBar(
                  title: const AppText('مشغل الدرس', style: AppTextStyle.title),
                ),
                body: Center(child: Text('تعذر تحميل الدرس: $e')),
              ),
              data: (lesson) {
                if (lesson.isFree) {
                  // الدرس مجاني: نعرض اختيار المحتوى
                  return _buildContentChoice(lesson, progressRepo, userId);
                }
                return Scaffold(
                  appBar: AppBar(
                    title: const AppText('مشغل الدرس', style: AppTextStyle.title),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              AppText('هذا الدرس مقفل',
                                  style: AppTextStyle.title),
                              SizedBox(height: AppSpacing.xs),
                              AppText(
                                'اشترك لفتح جميع الدروس غير المجانية.',
                                style: AppTextStyle.body,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'اشترك الآن لفتح الدروس',
                          onPressed: () => context.go('/subscription'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // مشترك أو درس مجاني: عرض المشغّل
          return lessonAsync.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              appBar: AppBar(
                title: const AppText('مشغل الدرس', style: AppTextStyle.title),
              ),
              body: Center(child: Text('تعذر تحميل الدرس: $e')),
            ),
            data: (lesson) => _buildContentChoice(lesson, progressRepo, userId),
          );
        },
      ),
    );
  }

  Widget _buildContentForUnsubscribed(
    WidgetRef ref,
    dynamic progressRepo,
    String userId,
  ) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));
    return lessonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const AppText('مشغل الدرس', style: AppTextStyle.title),
        ),
        body: Center(child: Text('تعذر تحميل الدرس: $e')),
      ),
      data: (lesson) {
        if (lesson.isFree) {
          return _buildPlayerScaffold(lesson, progressRepo, userId);
        }
        return Scaffold(
          appBar: AppBar(
            title: const AppText('مشغل الدرس', style: AppTextStyle.title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppText('هذا الدرس مقفل', style: AppTextStyle.title),
                      SizedBox(height: AppSpacing.xs),
                      AppText(
                        'اشترك لفتح جميع الدروس غير المجانية.',
                        style: AppTextStyle.body,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'اشترك الآن لفتح الدروس',
                  onPressed: () => context.go('/subscription'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerScaffold(
    Lesson lesson,
    dynamic progressRepo,
    String userId,
  ) {
    final needNewController = _currentUrl != lesson.videoUrl;

    if (needNewController) {
      _currentUrl = lesson.videoUrl;
      _controller?.removeListener(_onVideoUpdate);
      _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(lesson.videoUrl),
      )
        ..initialize().then((_) {
          _controller?.addListener(_onVideoUpdate);
          _controller?.setVolume(_volume);
          if (mounted) setState(() {});
        });
    }
    final isReady = _controller?.value.isInitialized ?? false;
    final position = _controller?.value.position ?? Duration.zero;
    final duration = _controller?.value.duration ?? Duration.zero;
    final durationSec = duration.inSeconds > 0 ? duration.inSeconds : lesson.durationSec;
    final totalDuration = Duration(seconds: durationSec);
    final progress = totalDuration.inMilliseconds > 0
        ? position.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: AppText(lesson.titleAr, style: AppTextStyle.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video: AspectRatio with controller.value.aspectRatio for dynamic video formats.
            // Fallback 16/9 when not ready. AppCard provides padding/border.
            AppCard(
              child: AspectRatio(
                aspectRatio: isReady && _controller!.value.aspectRatio > 0
                    ? _controller!.value.aspectRatio
                    : 16 / 9,
                  child: isReady
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(_controller!),
                          _VideoControlsOverlay(
                            controller: _controller!,
                            position: position,
                            totalDuration: totalDuration,
                            progress: clampedProgress,
                            volume: _volume,
                            onVolumeChanged: (v) {
                              setState(() => _volume = v);
                              _controller?.setVolume(v);
                            },
                            onSeek: (value) {
                              final to = Duration(
                                milliseconds: (value * totalDuration.inMilliseconds).round(),
                              );
                              _controller?.seekTo(to);
                            },
                            onSaveProgress: (value) {
                              if (userId.isNotEmpty) {
                                progressRepo.saveProgress(
                                  userId: userId,
                                  courseId: widget.courseId,
                                  lessonId: widget.lessonId,
                                  progressPercent: value,
                                  watchedSeconds: (value * lesson.durationSec.toDouble()).toInt(),
                                );
                              }
                            },
                            onFullscreen: () => _openFullscreen(context, lesson.titleAr),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, String title) {
    if (_controller == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _FullScreenVideoPage(
          controller: _controller!,
          title: title,
          formatDuration: _formatDuration,
          volume: _volume,
          onVolumeChanged: (v) {
            setState(() => _volume = v);
            _controller?.setVolume(v);
          },
        ),
      ),
    );
  }

  Widget _buildContentChoice(
    Lesson lesson,
    dynamic progressRepo,
    String userId,
  ) {
    final hasVideo = lesson.videoUrl.isNotEmpty;
    final hasTextFiles = lesson.textFileUrls.isNotEmpty;

    // If only one type of content, open it directly
    if (hasVideo && !hasTextFiles) {
      return _buildPlayerScaffold(lesson, progressRepo, userId);
    }
    if (!hasVideo && hasTextFiles) {
      return TextFileViewerScreen(lesson: lesson, courseId: widget.courseId);
    }

    // If both types exist, show choice screen
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: AppText(lesson.titleAr, style: AppTextStyle.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'اختر نوع المحتوى الذي تريد مشاهدته:',
                style: AppTextStyle.title,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Video option
              if (hasVideo)
                _buildContentOption(
                  icon: Icons.play_circle_filled,
                  title: 'مشاهدة الفيديو',
                  subtitle: '${lesson.durationSec ~/ 60} دقيقة',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => _buildPlayerScaffold(lesson, progressRepo, userId),
                    ),
                  ),
                ),
              
              if (hasVideo && hasTextFiles)
                const SizedBox(height: AppSpacing.md),
              
              // Text files option
              if (hasTextFiles)
                _buildContentOption(
                  icon: Icons.library_books,
                  title: 'الملفات النصية',
                  subtitle: '${lesson.textFileUrls.length} ملف نصي',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TextFileViewerScreen(
                          lesson: lesson,
                          courseId: widget.courseId,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      style: AppTextStyle.title,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      subtitle,
                      style: AppTextStyle.caption,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoControlsOverlay extends StatelessWidget {
  const _VideoControlsOverlay({
    required this.controller,
    required this.position,
    required this.totalDuration,
    required this.progress,
    required this.volume,
    required this.onVolumeChanged,
    required this.onSeek,
    required this.onSaveProgress,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final Duration position;
  final Duration totalDuration;
  final double progress;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSaveProgress;
  final VoidCallback onFullscreen;

  static String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  static const _playHeight = 64.0;
  static const _bottomContentHeight = 100.0;
  static const _verticalGap = 12.0;

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha:0.2),
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                final to = Duration(
                  milliseconds: (v * totalDuration.inMilliseconds).round(),
                );
                controller.seekTo(to);
              },
              onChangeEnd: (v) {
                onSeek(v);
                onSaveProgress(v);
              },
            ),
          ),
          // Row: use MainAxisSize.min; wrap time Text in Flexible to prevent overflow on
          // narrow screens (was causing RenderFlex overflow - Row expanded beyond constraints).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 22),
                onPressed: () {
                  final to = position - const Duration(seconds: 10);
                  controller.seekTo(to.isNegative ? Duration.zero : to);
                },
              ),
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                },
              ),
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 22),
                onPressed: () {
                  final to = position + const Duration(seconds: 10);
                  final max = totalDuration;
                  controller.seekTo(to > max ? max : to);
                },
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${_format(position)} / ${_format(totalDuration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 52,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    onChanged: (v) => onVolumeChanged(v),
                  ),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  volume <= 0 ? Icons.volume_off : (volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => onVolumeChanged(volume > 0 ? 0 : 1),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                onPressed: onFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          final maxW = constraints.maxWidth;
          final bottomAvailable = maxH - _playHeight - _verticalGap;
          final bottomHeight = bottomAvailable.clamp(0.0, _bottomContentHeight);

          return Column(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Center(
                child: IconButton(
                  iconSize: _playHeight,
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                ),
              ),
              if (bottomHeight > 0)
                SizedBox(
                  height: bottomHeight,
                  width: maxW,
                  child: ClipRect(
                    child: UnconstrainedBox(
                      alignment: Alignment.topCenter,
                      constrainedAxis: Axis.vertical,
                      child: Transform.scale(
                        scale: bottomHeight / _bottomContentHeight,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: maxW,
                          height: _bottomContentHeight,
                          child: _buildBottomControls(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FullScreenVideoPage extends StatefulWidget {
  const _FullScreenVideoPage({
    required this.controller,
    required this.title,
    required this.formatDuration,
    required this.volume,
    required this.onVolumeChanged,
  });

  final VideoPlayerController controller;
  final String title;
  final String Function(Duration) formatDuration;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  void _listener() => setState(() {});

  late double _volume;

  @override
  void initState() {
    super.initState();
    _volume = widget.volume;
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _setVolume(double v) {
    setState(() => _volume = v.clamp(0.0, 1.0));
    widget.controller.setVolume(_volume);
    widget.onVolumeChanged(_volume);
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final total = duration.inMilliseconds > 0 ? duration : Duration(seconds: 1);
    final progress = total.inMilliseconds > 0
        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                // Use controller aspect ratio; fallback 16/9 if invalid (prevents layout issues).
                aspectRatio: widget.controller.value.aspectRatio > 0
                    ? widget.controller.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(widget.controller),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black54,
                leading: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.primary,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (v) {
                          final to = Duration(
                            milliseconds: (v * total.inMilliseconds).round(),
                          );
                          widget.controller.seekTo(to);
                        },
                      ),
                    ),
                    // Row: wrap time Text in Flexible to prevent overflow on narrow screens.
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () {
                            final to = position - const Duration(seconds: 10);
                            widget.controller.seekTo(to.isNegative ? Duration.zero : to);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            if (widget.controller.value.isPlaying) {
                              widget.controller.pause();
                            } else {
                              widget.controller.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () {
                            final to = position + const Duration(seconds: 10);
                            widget.controller.seekTo(to > total ? total : to);
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${widget.formatDuration(position)} / ${widget.formatDuration(total)}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 80,
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.white70,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white24,
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: _volume.clamp(0.0, 1.0),
                              onChanged: _setVolume,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _volume <= 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                            color: Colors.white,
                          ),
                          onPressed: () => _setVolume(_volume > 0 ? 0 : 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

