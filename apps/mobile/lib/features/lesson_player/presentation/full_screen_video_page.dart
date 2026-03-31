import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';
import 'package:video_player/video_player.dart';

/// شاشة فيديو بملء الشاشة الحقيقي فوق كل واجهة التطبيق (root navigator).
///
/// يُفترض فتحها عبر [Navigator.of(context, rootNavigator: true)] حتى لا تبقى
/// شريط "Everest" أو شريط التنقل السفلي ظاهرين.
class FullScreenVideoPage extends StatefulWidget {
  const FullScreenVideoPage({
    super.key,
    required this.controller,
    required this.initialVolume,
    required this.onVolumeChanged,
    required this.totalDuration,
    this.lessonTitle,
    this.onSaveProgress,
  });

  final VideoPlayerController controller;
  final double initialVolume;
  final ValueChanged<double> onVolumeChanged;
  final Duration totalDuration;

  /// للوصولية فقط (لا يُعرض كشريط تطبيق).
  final String? lessonTitle;

  /// يُستدعى عند انتهاء السحب على شريط التقدم (0.0–1.0).
  final ValueChanged<double>? onSaveProgress;

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late double _volume;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    widget.controller.addListener(_onControllerTick);
    _enterImmersive();
    _scheduleHideControls();
  }

  Future<void> _enterImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// يُستدعى عند الخروج من الشاشة (زر، رجوع، أو إزالة المسار).
  void _restoreNormalChrome() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }


  void _scheduleHideControls() {
    _hideTimer?.cancel();
    if (!_controlsVisible) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _scheduleHideControls();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onUserInteraction() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _scheduleHideControls();
  }

  void _setVolume(double v) {
    final nv = v.clamp(0.0, 1.0);
    setState(() => _volume = nv);
    widget.controller.setVolume(nv);
    widget.onVolumeChanged(nv);
    _onUserInteraction();
  }

  static String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onControllerTick);
    _restoreNormalChrome();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final position = c.value.position;
    final duration = c.value.duration;
    final total = widget.totalDuration.inMilliseconds > 0
        ? widget.totalDuration
        : (duration.inMilliseconds > 0 ? duration : const Duration(seconds: 1));
    final progress = total.inMilliseconds > 0
        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _restoreNormalChrome();
      },
      child: Semantics(
        label: widget.lessonTitle ?? 'مشغل الفيديو',
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: c.value.isInitialized && c.value.size.width > 0
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: c.value.size.width,
                          height: c.value.size.height,
                          child: VideoPlayer(c),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      ),
              ),
          if (!_controlsVisible)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _controlsVisible = true);
                  _scheduleHideControls();
                },
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          if (_controlsVisible)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.2, 0.62, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.paddingOf(context).top + 4,
                        left: 4,
                        right: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            tooltip: 'إغلاق ملء الشاشة',
                            onPressed: () {
                              _hideTimer?.cancel();
                              _restoreNormalChrome();
                              Navigator.of(context).pop();
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleControls,
                        child: const ColoredBox(color: Colors.transparent),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: MediaQuery.paddingOf(context).bottom + 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppColors.primary,
                              overlayColor: AppColors.primary.withValues(alpha: 0.25),
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChangeStart: (_) => _onUserInteraction(),
                              onChanged: (v) {
                                _onUserInteraction();
                                final to = Duration(
                                  milliseconds: (v * total.inMilliseconds).round(),
                                );
                                c.seekTo(to);
                              },
                              onChangeEnd: (v) {
                                widget.onSaveProgress?.call(v);
                              },
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                                onPressed: () {
                                  _onUserInteraction();
                                  final to = position - const Duration(seconds: 10);
                                  c.seekTo(to.isNegative ? Duration.zero : to);
                                },
                              ),
                              IconButton(
                                iconSize: 48,
                                icon: Icon(
                                  c.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _onUserInteraction();
                                  if (c.value.isPlaying) {
                                    c.pause();
                                  } else {
                                    c.play();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                                onPressed: () {
                                  _onUserInteraction();
                                  final to = position + const Duration(seconds: 10);
                                  c.seekTo(to > total ? total : to);
                                },
                              ),
                              Expanded(
                                child: Text(
                                  '${_format(position)} / ${_format(total)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 88,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: Colors.white70,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                  ),
                                  child: Slider(
                                    value: _volume.clamp(0.0, 1.0),
                                    onChangeStart: (_) => _onUserInteraction(),
                                    onChanged: _setVolume,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _volume <= 0
                                      ? Icons.volume_off_rounded
                                      : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _onUserInteraction();
                                  _setVolume(_volume > 0 ? 0 : 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
