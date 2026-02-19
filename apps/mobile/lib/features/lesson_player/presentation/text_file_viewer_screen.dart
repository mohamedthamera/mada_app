import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/widgets.dart';

class TextFileViewerScreen extends ConsumerStatefulWidget {
  const TextFileViewerScreen({
    super.key,
    required this.lesson,
    required this.courseId,
  });

  final Lesson lesson;
  final String courseId;

  @override
  ConsumerState<TextFileViewerScreen> createState() => _TextFileViewerScreenState();
}

class _TextFileViewerScreenState extends ConsumerState<TextFileViewerScreen> {
  int _currentFileIndex = 0;
  Map<String, String> _fileContents = {};
  Map<String, bool> _loadingStates = {};
  Map<String, String> _errorStates = {};

  @override
  void initState() {
    super.initState();
    _loadAllFiles();
  }

  Future<void> _loadAllFiles() async {
    for (int i = 0; i < widget.lesson.textFileUrls.length; i++) {
      final url = widget.lesson.textFileUrls[i];
      setState(() {
        _loadingStates[url] = true;
        _errorStates[url] = '';
      });
      await _loadFileContent(url);
    }
  }

  Future<void> _loadFileContent(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _fileContents[url] = response.data.toString();
          _loadingStates[url] = false;
        });
      } else {
        setState(() {
          _errorStates[url] = 'فشل تحميل الملف: ${response.statusCode}';
          _loadingStates[url] = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorStates[url] = 'خطأ في تحميل الملف: $e';
        _loadingStates[url] = false;
      });
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل فتح الملف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: AppText(widget.lesson.titleAr, style: AppTextStyle.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (widget.lesson.textFileUrls.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadFile(
                  widget.lesson.textFileUrls[_currentFileIndex],
                  widget.lesson.textFileNames[_currentFileIndex],
                ),
                tooltip: 'تحميل الملف',
              ),
          ],
        ),
        body: Column(
          children: [
            // File tabs
            if (widget.lesson.textFileUrls.length > 1)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: widget.lesson.textFileUrls.length,
                  itemBuilder: (context, index) {
                    final fileName = widget.lesson.textFileNames[index];
                    final isSelected = index == _currentFileIndex;
                    return Container(
                      margin: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _currentFileIndex = index),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: AppText(
                                fileName.length > 15
                                    ? '${fileName.substring(0, 15)}...'
                                    : fileName,
                                style: AppTextStyle.body,
                                color: isSelected
                                    ? AppColors.primaryForeground
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Content area
            Expanded(
              child: _buildContentArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    final url = widget.lesson.textFileUrls[_currentFileIndex];
    final fileName = widget.lesson.textFileNames[_currentFileIndex];

    if (_loadingStates[url] == true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            AppText('جاري تحميل الملف...', style: AppTextStyle.body),
          ],
        ),
      );
    }

    if (_errorStates[url] != null && _errorStates[url]!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
              AppText(
                'خطأ في تحميل الملف',
                style: AppTextStyle.title,
                color: AppColors.danger,
                align: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                _errorStates[url]!,
                style: AppTextStyle.body,
                align: TextAlign.center,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'إعادة المحاولة',
                onPressed: () => _loadFileContent(url),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'تحميل الملف',
                onPressed: () => _downloadFile(url, fileName),
              ),
            ],
          ),
        ),
      );
    }

    final content = _fileContents[url];
    if (content == null || content.isEmpty) {
      return const Center(
        child: AppText('الملف فارغ', style: AppTextStyle.body),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              fileName,
              style: AppTextStyle.title,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: AppText(
                content,
                style: AppTextStyle.body,
                align: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
