import 'dart:async' show unawaited;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'book_viewer_io_impl.dart' if (dart.library.html) 'book_viewer_io_stub.dart'
    as book_io;

/// عارض كتب PDF — **تدفق التحميل أولاً** (مشابه لتيليجرام): تنزيل مع تقدم، ثم خيارات
/// فتح خارجي / داخل التطبيق / حفظ نسخة. لا يُعرض PDF تلقائياً بعد التحميل.
///
/// - **الموبايل:** [Dio.download] يُدفق إلى ملف؛ مع [bookCacheKey] يُستخدم التخزين المؤقت ولا يُعاد التحميل.
/// - **الويب:** [SfPdfViewer.network] كما سبق.
class BookViewerScreen extends StatefulWidget {
  const BookViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    this.headers,
    this.refreshSignedUrl,
    this.bookCacheKey,
    this.expectedFileSizeBytes,
  });

  final String title;
  final String pdfUrl;
  final Map<String, String>? headers;
  final Future<String> Function()? refreshSignedUrl;
  final String? bookCacheKey;
  final int? expectedFileSizeBytes;

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

enum _MobileUiPhase {
  invalidUrl,
  checkingCache,
  downloading,
  ready,
  inAppView,
  errorDownload,
  errorViewer,
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  static const _shellBackground = Color(0xFF0F0F0F);
  static const _cardBackground = Color(0xFF1E1E1E);
  static const _accent = Color(0xFF3390EC);
  static const _logTag = '[BookViewer]';

  _MobileUiPhase _mobilePhase = _MobileUiPhase.checkingCache;
  String _mobileErrorMessage = '';

  Object? _localFile;

  bool _webViewerFailed = false;
  String _webViewerError = '';

  CancelToken? _cancelToken;

  int _downloadReceived = 0;
  int _downloadTotal = 0;

  /// حجم الملف على القرص (للعرض بعد التحميل أو من التخزين المؤقت).
  int? _resolvedFileSizeBytes;

  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(minutes: 15),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (code) => code != null && code >= 200 && code < 400,
      headers: const {
        'Accept': 'application/pdf,application/octet-stream,*/*',
      },
    ),
  );

  void _logDiag(String message) {
    if (kDebugMode) {
      debugPrint('$_logTag $message');
    }
  }

  void _logError(String message, [StackTrace? st]) {
    debugPrint('$_logTag ERROR: $message');
    if (st != null && kDebugMode) {
      debugPrintStack(stackTrace: st, label: _logTag);
    }
  }

  void _safePostFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
    });
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} ك.ب';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} م.ب';
    return '${(mb / 1024).toStringAsFixed(2)} ج.ب';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(BookViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfUrl != widget.pdfUrl ||
        !mapEquals(oldWidget.headers, widget.headers) ||
        oldWidget.refreshSignedUrl != widget.refreshSignedUrl ||
        oldWidget.bookCacheKey != widget.bookCacheKey) {
      _cancelToken?.cancel();
      unawaited(_afterWidgetChangeRemount());
    }
  }

  Future<void> _afterWidgetChangeRemount() async {
    _localFile = null;
    if (!mounted) return;
    _bootstrap();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<String> _resolveDownloadUrl() async {
    if (widget.refreshSignedUrl != null) {
      _logDiag('resolve URL via refreshSignedUrl');
      final u = await widget.refreshSignedUrl!();
      final t = u.trim();
      if (t.isEmpty) {
        throw StateError('refreshSignedUrl returned an empty URL');
      }
      _logDiag('resolved URL length=${t.length}');
      return t;
    }
    return widget.pdfUrl.trim();
  }

  void _bootstrap() {
    final initial = widget.pdfUrl.trim();
    _logDiag(
      'bootstrap kIsWeb=$kIsWeb pdfUrlLen=${initial.length} cacheKey=${widget.bookCacheKey} hasRefresh=${widget.refreshSignedUrl != null}',
    );

    if (initial.isEmpty && widget.refreshSignedUrl == null) {
      setState(() {
        _mobilePhase = _MobileUiPhase.invalidUrl;
        _mobileErrorMessage = 'رابط الملف غير متوفر.';
        _webViewerFailed = false;
        _webViewerError = '';
      });
      return;
    }

    if (kIsWeb) {
      if (initial.isEmpty) {
        setState(() {
          _mobilePhase = _MobileUiPhase.invalidUrl;
          _mobileErrorMessage = 'رابط الملف غير متوفر.';
        });
        return;
      }
      final parsed = Uri.tryParse(initial);
      if (parsed == null ||
          !parsed.hasScheme ||
          (parsed.scheme != 'http' && parsed.scheme != 'https')) {
        setState(() {
          _mobilePhase = _MobileUiPhase.invalidUrl;
          _mobileErrorMessage = 'رابط الملف غير صالح.';
        });
        return;
      }
      setState(() {
        _mobilePhase = _MobileUiPhase.ready;
        _webViewerFailed = false;
        _webViewerError = '';
      });
      return;
    }

    if (initial.isEmpty && widget.refreshSignedUrl != null) {
      unawaited(_mobileFlowAfterUrlOk());
      return;
    }

    final parsed = Uri.tryParse(initial);
    if (parsed == null ||
        !parsed.hasScheme ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      if (widget.refreshSignedUrl == null) {
        setState(() {
          _mobilePhase = _MobileUiPhase.invalidUrl;
          _mobileErrorMessage = 'رابط الملف غير صالح.';
        });
        return;
      }
    }

    unawaited(_mobileFlowAfterUrlOk());
  }

  Future<void> _mobileFlowAfterUrlOk() async {
    setState(() {
      _mobilePhase = _MobileUiPhase.checkingCache;
      _mobileErrorMessage = '';
      _downloadReceived = 0;
      _downloadTotal = 0;
    });

    final cached = await book_io.tryGetCachedBookPdf(widget.bookCacheKey);
    if (!mounted) return;
    if (cached != null) {
      book_io.logLocalFileDebug(cached.localFileRef);
      _logDiag('using cached PDF (no download)');
      final sz = await book_io.getLocalFileSizeBytes(cached.localFileRef);
      if (!mounted) return;
      setState(() {
        _localFile = cached.localFileRef;
        _resolvedFileSizeBytes = sz > 0 ? sz : null;
        _mobilePhase = _MobileUiPhase.ready;
      });
      return;
    }

    await _runMobileDownload(forceRefresh: false);
  }

  Future<void> _runMobileDownload({required bool forceRefresh}) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    if (forceRefresh &&
        widget.bookCacheKey != null &&
        widget.bookCacheKey!.isNotEmpty) {
      await book_io.deleteCachedBookPdf(widget.bookCacheKey!);
    }

    setState(() {
      _mobilePhase = _MobileUiPhase.downloading;
      _mobileErrorMessage = '';
      _localFile = null;
      _resolvedFileSizeBytes = null;
      _downloadReceived = 0;
      _downloadTotal = 0;
    });

    String? outputPath;
    try {
      final url = await _resolveDownloadUrl();
      _logDiag('dio.download (stream-to-disk) url.length=${url.length}');

      if (url.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: url),
          message: 'رابط التنزيل فارغ.',
        );
      }
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw DioException(
          requestOptions: RequestOptions(path: url),
          message: 'رابط التنزيل غير صالح.',
        );
      }

      final mergedHeaders = <String, String>{
        'Accept': 'application/pdf,application/octet-stream,*/*',
        ...?widget.headers,
      };

      outputPath = await book_io.resolveBookPdfCachePath(widget.bookCacheKey);
      _logDiag('destination path=$outputPath');

      final load = await book_io.downloadPdfToPath(
        dio: _dio,
        url: url,
        fullOutputPath: outputPath,
        cancelToken: token,
        headers: mergedHeaders,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _downloadReceived = received;
            _downloadTotal = total;
          });
        },
      );

      _logDiag(
        'download finished status=${load.statusCode} → validating on disk',
      );

      final validationError =
          await book_io.validatePdfFileOnDisk(load.localFileRef, load.headers);
      if (validationError != null) {
        _logError('validation: $validationError');
        await book_io.deletePersistedPdfFile(load.localFileRef);
        if (!mounted) return;
        setState(() {
          _mobilePhase = _MobileUiPhase.errorDownload;
          _mobileErrorMessage = validationError;
        });
        return;
      }

      book_io.logLocalFileDebug(load.localFileRef);
      _logDiag('PDF ready → action sheet');

      if (!mounted) return;
      final sz = await book_io.getLocalFileSizeBytes(load.localFileRef);
      if (!mounted) return;
      setState(() {
        _localFile = load.localFileRef;
        _resolvedFileSizeBytes = sz > 0 ? sz : _downloadReceived;
        _mobilePhase = _MobileUiPhase.ready;
      });
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel) {
        _logDiag('download cancelled');
        if (!mounted) return;
        setState(() {
          _mobilePhase = _MobileUiPhase.errorDownload;
          _mobileErrorMessage = 'تم إلغاء التحميل.';
        });
        return;
      }
      _logError('DioException ${e.type}: ${e.message}', st);
      final failedPath = outputPath;
      if (failedPath != null && failedPath.isNotEmpty) {
        await book_io.deleteFileAtPathIfExists(failedPath);
      }
      if (!mounted) return;
      setState(() {
        _mobilePhase = _MobileUiPhase.errorDownload;
        _mobileErrorMessage = _userMessageForDio(e);
      });
    } catch (e, st) {
      _logError('Exception: $e', st);
      final partialPath = outputPath;
      if (partialPath != null && partialPath.isNotEmpty) {
        await book_io.deleteFileAtPathIfExists(partialPath);
      }
      if (!mounted) return;
      setState(() {
        _mobilePhase = _MobileUiPhase.errorDownload;
        _mobileErrorMessage = switch (e) {
          StateError s => s.message,
          _ => 'فشل التحميل أو حفظ الملف. حاول مرة أخرى.',
        };
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  static String _userMessageForDio(DioException e) {
    final code = e.response?.statusCode;
    if (code == 403 || code == 401) {
      return 'انتهت صلاحية الرابط أو لا تملك صلاحية ($code). «إعادة المحاولة» تجلب رابطاً جديداً.';
    }
    if (code == 404) {
      return 'الملف غير موجود (404).';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال. تحقق من الشبكة.';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالخادم.';
      case DioExceptionType.badResponse:
        return code != null ? 'خطأ خادم ($code).' : 'استجابة غير صالحة.';
      case DioExceptionType.cancel:
        return 'أُلغي التحميل.';
      default:
        return e.message?.isNotEmpty == true ? e.message! : 'تعذر التحميل.';
    }
  }

  Future<void> _openExternal() async {
    if (_localFile == null) return;
    final err = await book_io.openPdfExternally(_localFile!);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Future<void> _saveCopy() async {
    if (_localFile == null) return;
    final err = await book_io.savePdfCopyToDocuments(_localFile!, widget.title);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          // null = نجاح النسخ؛ نص = رسالة خطأ
          err ?? 'تم حفظ نسخة في مجلد المستندات (MadaBooks).',
        ),
      ),
    );
  }

  void _openInApp() {
    setState(() => _mobilePhase = _MobileUiPhase.inAppView);
  }

  Widget _shell({required Widget child}) {
    return ColoredBox(
      color: _shellBackground,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _shellBackground,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: !kIsWeb && _mobilePhase == _MobileUiPhase.inAppView
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _mobilePhase = _MobileUiPhase.ready);
                  },
                )
              : null,
          automaticallyImplyLeading:
              kIsWeb || _mobilePhase != _MobileUiPhase.inAppView,
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: kIsWeb ? _buildWebBody(context) : _buildMobileBody(context),
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    switch (_mobilePhase) {
      case _MobileUiPhase.invalidUrl:
        return _shell(
          child: _InvalidUrlBody(message: _mobileErrorMessage),
        );
      case _MobileUiPhase.checkingCache:
        return _shell(
          child: const _CenteredStatus(
            icon: Icons.folder_open_rounded,
            title: 'جاري التحقق من الملف المحلي...',
            subtitle: null,
          ),
        );
      case _MobileUiPhase.downloading:
        return _shell(
          child: _DownloadProgressBody(
            title: widget.title,
            received: _downloadReceived,
            total: _downloadTotal,
            expectedBytes: widget.expectedFileSizeBytes,
            onCancel: _cancelDownload,
          ),
        );
      case _MobileUiPhase.errorDownload:
        return _shell(
          child: _ErrorStateBody(
            message: _mobileErrorMessage,
            onRetry: () => unawaited(_runMobileDownload(forceRefresh: false)),
            onBack: () => Navigator.of(context).pop(),
          ),
        );
      case _MobileUiPhase.errorViewer:
        return _shell(
          child: _ErrorStateBody(
            message: _mobileErrorMessage,
            onRetry: () => setState(() => _mobilePhase = _MobileUiPhase.ready),
            onBack: () => Navigator.of(context).pop(),
          ),
        );
      case _MobileUiPhase.ready:
        if (_localFile == null) {
          return _shell(
            child: const _InvalidUrlBody(
              message: 'تعذر تجهيز الملف.',
            ),
          );
        }
        return _shell(
          child: _TelegramStyleActions(
            title: widget.title,
            fileLabel: _formatBytes(
              _resolvedFileSizeBytes ??
                  (_downloadReceived > 0
                      ? _downloadReceived
                      : (widget.expectedFileSizeBytes ?? 0)),
            ),
            hasKnownSize: _resolvedFileSizeBytes != null ||
                widget.expectedFileSizeBytes != null ||
                _downloadTotal > 0 ||
                _downloadReceived > 0,
            onOpenExternal: _openExternal,
            onOpenInApp: _openInApp,
            onSaveCopy: _saveCopy,
            onRedownload: widget.bookCacheKey != null &&
                    widget.bookCacheKey!.isNotEmpty
                ? () => unawaited(_runMobileDownload(forceRefresh: true))
                : () => unawaited(_runMobileDownload(forceRefresh: false)),
            showRedownload: true,
          ),
        );
      case _MobileUiPhase.inAppView:
        if (_localFile == null) {
          return _shell(
            child: const _InvalidUrlBody(message: 'الملف غير متوفر.'),
          );
        }
        return book_io.buildMobileSfPdfFileViewer(
          key: ValueKey<Object>(_localFile!),
          file: _localFile!,
          onDocumentLoaded: () {
            _logDiag('Syncfusion onDocumentLoaded (file)');
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            final err = details.description.isNotEmpty
                ? details.description
                : details.error;
            _logError('Syncfusion onDocumentLoadFailed: $err');
            _safePostFrame(() {
              if (!mounted) return;
              setState(() {
                _mobilePhase = _MobileUiPhase.errorViewer;
                _mobileErrorMessage =
                    err.isNotEmpty ? err : 'تعذر عرض ملف PDF.';
              });
            });
          },
        );
    }
  }

  Widget _buildWebBody(BuildContext context) {
    final url = widget.pdfUrl.trim();

    if (_mobilePhase == _MobileUiPhase.invalidUrl) {
      return _shell(
        child: _InvalidUrlBody(message: _mobileErrorMessage),
      );
    }

    if (_webViewerFailed) {
      return _shell(
        child: _ErrorStateBody(
          message: _webViewerError.isNotEmpty
              ? _webViewerError
              : 'تعذر تحميل PDF من الشبكة.',
          onRetry: () {
            setState(() {
              _webViewerFailed = false;
              _webViewerError = '';
            });
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    _logDiag('web SfPdfViewer.network');
    return ColoredBox(
      color: Colors.white,
      child: SizedBox.expand(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SfPdfViewer.network(
            url,
            key: ValueKey<String>(url),
            headers: widget.headers,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            canShowPageLoadingIndicator: true,
            enableDoubleTapZooming: true,
            maxZoomLevel: 5,
            interactionMode: PdfInteractionMode.pan,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            enableHyperlinkNavigation: false,
            onDocumentLoaded: (_) {
              _logDiag('Syncfusion onDocumentLoaded (web)');
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              final err = details.description.isNotEmpty
                  ? details.description
                  : details.error;
              _logError('web onDocumentLoadFailed: $err');
              _safePostFrame(() {
                if (!mounted) return;
                setState(() {
                  _webViewerFailed = true;
                  _webViewerError = err;
                });
              });
            },
          ),
        ),
      ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: _BookViewerScreenState._accent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadProgressBody extends StatelessWidget {
  const _DownloadProgressBody({
    required this.title,
    required this.received,
    required this.total,
    required this.expectedBytes,
    required this.onCancel,
  });

  final String title;
  final int received;
  final int total;
  final int? expectedBytes;
  final VoidCallback onCancel;

  double? get _fraction {
    if (total > 0) return (received / total).clamp(0.0, 1.0);
    final exp = expectedBytes;
    if (exp != null && exp > 0) {
      return (received / exp).clamp(0.0, 1.0);
    }
    return null;
  }

  String _sizeLine() {
    final rec = _BookViewerScreenState._formatBytes(received);
    if (total > 0) {
      return '$rec / ${_BookViewerScreenState._formatBytes(total)}';
    }
    if (expectedBytes != null && expectedBytes! > 0) {
      return '$rec / ~${_BookViewerScreenState._formatBytes(expectedBytes!)}';
    }
    return rec;
  }

  String? _percentText() {
    final f = _fraction;
    if (f == null) return null;
    return '${(f * 100).clamp(0, 100).toStringAsFixed(0)}٪';
  }

  @override
  Widget build(BuildContext context) {
    final pct = _percentText();
    final frac = _fraction;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _BookViewerScreenState._cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _BookViewerScreenState._accent
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: _BookViewerScreenState._accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'جاري التنزيل…',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (frac != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: _BookViewerScreenState._accent,
                      ),
                    )
                  else
                    const LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      color: _BookViewerScreenState._accent,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sizeLine(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (pct != null)
                        Text(
                          pct,
                          style: const TextStyle(
                            color: _BookViewerScreenState._accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.close),
              label: const Text('إلغاء التحميل'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelegramStyleActions extends StatelessWidget {
  const _TelegramStyleActions({
    required this.title,
    required this.fileLabel,
    required this.hasKnownSize,
    required this.onOpenExternal,
    required this.onOpenInApp,
    required this.onSaveCopy,
    required this.onRedownload,
    required this.showRedownload,
  });

  final String title;
  final String fileLabel;
  final bool hasKnownSize;
  final VoidCallback onOpenExternal;
  final VoidCallback onOpenInApp;
  final VoidCallback onSaveCopy;
  final VoidCallback onRedownload;
  final bool showRedownload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _BookViewerScreenState._cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasKnownSize ? 'PDF · $fileLabel' : 'PDF',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'اختر طريقة الفتح',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.open_in_new_rounded,
            iconBg: _BookViewerScreenState._accent.withValues(alpha: 0.2),
            iconColor: _BookViewerScreenState._accent,
            label: 'فتح بتطبيق خارجي',
            subtitle: 'Adobe، الملفات، Chrome…',
            onTap: onOpenExternal,
            emphasized: true,
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.visibility_rounded,
            iconBg: Colors.white12,
            iconColor: Colors.white70,
            label: 'معاينة داخل التطبيق',
            subtitle: 'اختياري — قد يكون أبطأ للملفات الضخمة',
            onTap: onOpenInApp,
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.save_alt_rounded,
            iconBg: Colors.white12,
            iconColor: Colors.white70,
            label: 'حفظ نسخة في المستندات',
            subtitle: 'مجلد MadaBooks',
            onTap: onSaveCopy,
          ),
          if (showRedownload) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRedownload,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('تحميل من جديد'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized
          ? _BookViewerScreenState._accent.withValues(alpha: 0.12)
          : _BookViewerScreenState._cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvalidUrlBody extends StatelessWidget {
  const _InvalidUrlBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.arrow_back),
              label: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStateBody extends StatelessWidget {
  const _ErrorStateBody({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              'تعذر إكمال التحميل',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: _BookViewerScreenState._accent,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
                OutlinedButton.icon(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('رجوع'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
