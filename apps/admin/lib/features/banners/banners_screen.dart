import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'presentation/admin_banner_providers.dart';
import '../../core/widgets/admin_widgets.dart';

class BannersScreen extends ConsumerWidget {
  const BannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: adminAppBarLeading(context),
        title: const Text('إدارة البنرات الإعلانية'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddBannerDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('إضافة بنر جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(child: Text('لا توجد بنرات حالياً'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: banner.imageUrl.isEmpty
                        ? (banner.videoUrl != null && banner.videoUrl!.isNotEmpty)
                            ? _VideoPreview(url: banner.videoUrl!)
                            : Container(
                                width: 120,
                                height: 60,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Text('لا معاينة'),
                                ),
                              )
                        : Image.network(
                            banner.imageUrl,
                            width: 120,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 120,
                                  height: 60,
                                  color: Colors.grey,
                                ),
                          ),
                  ),
                  title: Text(banner.title ?? 'بدون عنوان'),
                  subtitle: Text(
                    'الترتيب: ${banner.orderIndex} | نشط: ${banner.isActive ? "نعم" : "لا"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showEditBannerDialog(context, ref, banner),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmation(context, ref, banner),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const BannerFormDialog(),
    );
  }

  void _showEditBannerDialog(
    BuildContext context,
    WidgetRef ref,
    BannerModel banner,
  ) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(banner: banner),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    BannerModel banner,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا البنر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(adminBannerActionProvider.notifier)
                  .deleteBanner(
                    banner.id,
                    banner.imageUrl,
                    videoUrl: banner.videoUrl,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class BannerFormDialog extends ConsumerStatefulWidget {
  final BannerModel? banner;
  const BannerFormDialog({super.key, this.banner});

  @override
  ConsumerState<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _linkController;
  late TextEditingController _orderController;
  bool _isActive = true;
  Uint8List? _selectedImage;
  String? _fileName;
  Uint8List? _selectedVideo;
  String? _videoFileName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner?.title);
    _linkController = TextEditingController(text: widget.banner?.linkUrl);
    _orderController = TextEditingController(
      text: (widget.banner?.orderIndex ?? 0).toString(),
    );
    _isActive = widget.banner?.isActive ?? true;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = await _bytesFromPlatformFile(file);
    if (bytes == null) return;
    setState(() {
      _selectedImage = bytes;
      _fileName = file.name;
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = await _bytesFromPlatformFile(file);
    if (bytes == null) return;
    setState(() {
      _selectedVideo = bytes;
      _videoFileName = file.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(adminBannerActionProvider).isLoading;

    return AlertDialog(
      title: Text(widget.banner == null ? 'إضافة بنر جديد' : 'تعديل البنر'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.banner == null || _selectedImage != null) ...[
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? Image.memory(_selectedImage!, fit: BoxFit.cover)
                        : const Center(child: Text('اضغط لاختيار صورة')),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'الفيديو (اختياري)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam_outlined),
                      label: Text(_videoFileName ?? 'اختيار فيديو'),
                    ),
                  ),
                  if (_videoFileName != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'إزالة الفيديو',
                      onPressed: _clearVideo,
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان (اختياري)',
                ),
              ),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'رابط التوجيه (اختياري)',
                ),
              ),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(labelText: 'الترتيب'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'مطلوب' : null,
              ),
              SwitchListTile(
                title: const Text('نشط'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.banner == null &&
        _selectedImage == null &&
        _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة أو فيديو')),
      );
      return;
    }

    final banner = BannerModel(
      id: widget.banner?.id ?? '',
      imageUrl: widget.banner?.imageUrl ?? '',
      title: _titleController.text.isEmpty ? null : _titleController.text,
      linkUrl: _linkController.text.isEmpty ? null : _linkController.text,
      orderIndex: int.parse(_orderController.text),
      isActive: _isActive,
    );

    if (widget.banner == null) {
      await ref
          .read(adminBannerActionProvider.notifier)
          .addBanner(
            banner: banner,
            imageBytes: _selectedImage,
            fileName: _fileName,
            videoBytes: _selectedVideo,
            videoFileName: _videoFileName,
          );
    } else {
      await ref
          .read(adminBannerActionProvider.notifier)
          .updateBanner(
            banner: banner,
            imageBytes: _selectedImage,
            fileName: _fileName,
            videoBytes: _selectedVideo,
            videoFileName: _videoFileName,
          );
    }

    if (context.mounted) Navigator.pop(context);
  }

  Future<Uint8List?> _bytesFromPlatformFile(PlatformFile pf) async {
    if (pf.bytes != null) return pf.bytes;
    if (pf.readStream != null) {
      final chunks = <int>[];
      await for (final chunk in pf.readStream!) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    }
    return null;
  }

  void _clearVideo() {
    setState(() {
      _selectedVideo = null;
      _videoFileName = null;
    });
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.url});
  final String url;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..setVolume(0.0)
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _controller?.play();
          }
        }).catchError((error) {
          // If video fails to load, show placeholder
          if (mounted) {
            setState(() => _initialized = false);
          }
        });
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        setState(() => _initialized = false);
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
    if (!_initialized || _controller == null) {
      return Container(
        width: 120,
        height: 60,
        color: Colors.grey.shade300,
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_outlined, size: 16),
              SizedBox(width: 4),
              Text('فيديو', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 120,
      height: 60,
      child: FittedBox(
        fit: BoxFit.cover,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
