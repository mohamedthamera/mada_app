import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'book_viewer_load_result.dart';

void _ioLog(String m) {
  if (kDebugMode) {
    debugPrint('[BookViewerIO] $m');
  }
}

void logLocalFileDebug(Object? file) {
  if (!kDebugMode) return;
  if (file is File) {
    final len = file.lengthSync();
    debugPrint('[BookViewerIO] activeLocalFile path=${file.path} sizeBytes=$len');
  }
}

Future<int> getLocalFileSizeBytes(Object file) async {
  final f = file as File;
  if (!await f.exists()) return 0;
  return f.length();
}

Future<Directory> getBookPdfCacheDirectory() async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory('${base.path}/book_pdfs');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<String> resolveBookPdfCachePath(String? bookCacheKey) async {
  final dir = await getBookPdfCacheDirectory();
  final name = (bookCacheKey != null && bookCacheKey.isNotEmpty)
      ? 'book_${bookCacheKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf'
      : 'book_${DateTime.now().millisecondsSinceEpoch}.pdf';
  return '${dir.path}/$name';
}

Future<void> deleteCachedBookPdf(String bookCacheKey) async {
  final path = await resolveBookPdfCachePath(bookCacheKey);
  final f = File(path);
  try {
    if (await f.exists()) {
      await f.delete();
      _ioLog('deleted cache $path');
    }
  } catch (e, st) {
    _ioLog('deleteCachedBookPdf error=$e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: st, label: '[BookViewerIO]');
    }
  }
}

Future<BookPdfLoadResult?> tryGetCachedBookPdf(String? bookCacheKey) async {
  if (bookCacheKey == null || bookCacheKey.isEmpty) return null;
  final path = await resolveBookPdfCachePath(bookCacheKey);
  final file = File(path);
  if (!await file.exists()) {
    _ioLog('cache miss path=$path');
    return null;
  }
  final len = await file.length();
  if (len == 0) {
    try {
      await file.delete();
    } catch (_) {}
    return null;
  }
  final emptyHeaders = Headers();
  final err = await validatePdfFileOnDisk(file, emptyHeaders);
  if (err != null) {
    _ioLog('cache invalid: $err → removing');
    try {
      await file.delete();
    } catch (_) {}
    return null;
  }
  _ioLog('cache HIT path=$path sizeBytes=$len');
  return BookPdfLoadResult(
    localFileRef: file,
    headers: emptyHeaders,
    statusCode: 200,
  );
}

Future<BookPdfLoadResult> downloadPdfToPath({
  required Dio dio,
  required String url,
  required String fullOutputPath,
  CancelToken? cancelToken,
  required Map<String, String> headers,
  void Function(int received, int total)? onReceiveProgress,
}) async {
  _ioLog('dio.download → $fullOutputPath');
  late Response<dynamic> response;
  try {
    response = await dio.download(
      url,
      fullOutputPath,
      cancelToken: cancelToken,
      options: Options(headers: headers),
      deleteOnError: true,
      onReceiveProgress: onReceiveProgress,
    );
  } catch (e, st) {
    _ioLog('download FAILED: $e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: st, label: '[BookViewerIO]');
    }
    rethrow;
  }

  final file = File(fullOutputPath);
  final len = await file.length();
  final code = response.statusCode;
  final ct = response.headers.value('content-type');
  _ioLog('download OK status=$code content-type=$ct sizeBytes=$len path=$fullOutputPath');

  return BookPdfLoadResult(
    localFileRef: file,
    headers: response.headers,
    statusCode: code,
  );
}

Future<String?> openPdfExternally(Object file) async {
  final path = (file as File).path;
  _ioLog('OpenFile.open path=$path');
  final result = await OpenFile.open(path, type: 'application/pdf');
  if (kDebugMode) {
    debugPrint('[BookViewerIO] OpenFile result type=${result.type} message=${result.message}');
  }
  if (result.type != ResultType.done) {
    return result.message.isNotEmpty
        ? result.message
        : 'تعذر فتح الملف بتطبيق خارجي.';
  }
  return null;
}

Future<String?> savePdfCopyToDocuments(Object file, String title) async {
  final src = file as File;
  if (!await src.exists()) {
    return 'الملف غير موجود.';
  }
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/MadaBooks');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  var safe = title
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  if (safe.isEmpty) safe = 'book';
  if (safe.length > 80) {
    safe = safe.substring(0, 80);
  }
  final destPath = '${dir.path}/$safe.pdf';
  final dest = File(destPath);
  try {
    await src.copy(dest.path);
    _ioLog('saved copy → ${dest.path}');
    return null;
  } catch (e, st) {
    _ioLog('savePdfCopyToDocuments error=$e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: st, label: '[BookViewerIO]');
    }
    return 'تعذر نسخ الملف: $e';
  }
}

int _pdfScanStart(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
    return 3;
  }
  return 0;
}

bool _looksLikeHtmlOrJson(Uint8List b) {
  if (b.isEmpty) return false;
  var i = 0;
  while (i < b.length &&
      i < 64 &&
      (b[i] == 0x20 || b[i] == 0x09 || b[i] == 0x0A || b[i] == 0x0D)) {
    i++;
  }
  if (i >= b.length) return false;
  final head = String.fromCharCodes(
    b.sublist(i, i + (b.length - i > 80 ? 80 : b.length - i)),
  ).toLowerCase();
  return head.startsWith('<!doctype') ||
      head.startsWith('<html') ||
      head.startsWith('<?xml') ||
      head.startsWith('{') ||
      head.startsWith('[') ||
      head.contains('<body');
}

bool _contentLengthMismatch(Headers headers, int actualLength) {
  final raw = headers.value('content-length');
  if (raw == null) return false;
  final expected = int.tryParse(raw.trim());
  if (expected == null) return false;
  return expected != actualLength;
}

bool _hasPdfSignature(Uint8List b) {
  final s = _pdfScanStart(b);
  if (b.length < s + 5) return false;
  if (b[s] == 0x25 &&
      b[s + 1] == 0x50 &&
      b[s + 2] == 0x44 &&
      b[s + 3] == 0x46 &&
      b[s + 4] == 0x2D) {
    return true;
  }
  final window = b.length - s > 4096 ? 4096 : b.length - s;
  return String.fromCharCodes(b.sublist(s, s + window)).contains('%PDF-');
}

bool _hasPdfTrailer(Uint8List b) {
  if (b.length < 200) return true;
  final tailSize = b.length > 4096 ? 4096 : b.length;
  final tail = b.sublist(b.length - tailSize);
  final s = String.fromCharCodes(tail);
  return s.contains('%%EOF') || s.contains('startxref');
}

Future<String?> validatePdfFileOnDisk(
  Object localFileRef,
  Headers responseHeaders,
) async {
  final file = localFileRef as File;
  final len = await file.length();
  final cl = responseHeaders.value('content-length');
  _ioLog('validate onDisk size=$len content-length=$cl');

  if (len == 0) {
    try {
      await file.delete();
    } catch (_) {}
    return 'الملف المحمّل فارغ.';
  }

  if (_contentLengthMismatch(responseHeaders, len)) {
    final expected = int.tryParse(cl!.trim());
    return 'حجم الملف على القرص ($len) لا يطابق Content-Length ($expected).';
  }

  final raf = await file.open(mode: FileMode.read);
  try {
    final headCount = math.min(4096, len);
    final head = await raf.read(headCount);
    final headBytes = Uint8List.fromList(head);

    if (_looksLikeHtmlOrJson(headBytes)) {
      return 'الاستجابة ليست PDF (HTML/JSON). تحقق من الرابط أو الصلاحيات.';
    }
    if (!_hasPdfSignature(headBytes)) {
      return 'الملف لا يبدأ بترويسة PDF صالحة (%PDF-).';
    }

    await raf.setPosition(math.max(0, len - 4096));
    final tail = await raf.read(math.min(4096, len));
    final tailBytes = Uint8List.fromList(tail);
    if (!_hasPdfTrailer(tailBytes)) {
      return 'ملف PDF يبدو غير مكتملاً (مقطوع).';
    }
  } finally {
    await raf.close();
  }

  _ioLog('validate OK (header+trailer)');
  return null;
}

Future<void> deletePersistedPdfFile(Object? file) async {
  if (file is! File) return;
  try {
    if (await file.exists()) {
      await file.delete();
      _ioLog('deleted ${file.path}');
    }
  } catch (e, st) {
    _ioLog('deletePersistedPdfFile error=$e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: st, label: '[BookViewerIO]');
    }
  }
}

Future<void> deleteFileAtPathIfExists(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
      _ioLog('deleted path=$path');
    }
  } catch (e, st) {
    _ioLog('deleteFileAtPathIfExists error=$e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: st, label: '[BookViewerIO]');
    }
  }
}

Widget buildMobileSfPdfFileViewer({
  required Key key,
  required Object file,
  required VoidCallback onDocumentLoaded,
  required void Function(PdfDocumentLoadFailedDetails details) onDocumentLoadFailed,
}) {
  return ColoredBox(
    color: Colors.white,
    child: SizedBox.expand(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SfPdfViewer.file(
          file as File,
          key: key,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          canShowPageLoadingIndicator: true,
          enableDoubleTapZooming: true,
          maxZoomLevel: 5,
          interactionMode: PdfInteractionMode.pan,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          enableHyperlinkNavigation: false,
          onDocumentLoaded: (_) => onDocumentLoaded(),
          onDocumentLoadFailed: onDocumentLoadFailed,
        ),
      ),
    ),
  );
}
