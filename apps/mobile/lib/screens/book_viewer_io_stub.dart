import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'book_viewer_load_result.dart';

Future<BookPdfLoadResult?> tryGetCachedBookPdf(String? bookCacheKey) async => null;

Future<BookPdfLoadResult> downloadPdfToPath({
  required Dio dio,
  required String url,
  required String fullOutputPath,
  CancelToken? cancelToken,
  required Map<String, String> headers,
  void Function(int received, int total)? onReceiveProgress,
}) async {
  throw UnsupportedError('downloadPdfToPath is mobile/desktop only');
}

Future<void> deleteCachedBookPdf(String bookCacheKey) async {}

Future<String?> openPdfExternally(Object file) async =>
    'فتح الملف خارجياً غير متاح على الويب.';

Future<String?> savePdfCopyToDocuments(Object file, String title) async =>
    'حفظ نسخة غير متاح على الويب.';

Future<String> resolveBookPdfCachePath(String? bookCacheKey) async => '';

Future<String?> validatePdfFileOnDisk(
  Object localFileRef,
  Headers responseHeaders,
) async =>
    null;

void logLocalFileDebug(Object? file) {}

Future<int> getLocalFileSizeBytes(Object file) async => 0;

Future<void> deletePersistedPdfFile(Object? file) async {}

Future<void> deleteFileAtPathIfExists(String path) async {}

Widget buildMobileSfPdfFileViewer({
  required Key key,
  required Object file,
  required VoidCallback onDocumentLoaded,
  required void Function(PdfDocumentLoadFailedDetails details) onDocumentLoadFailed,
}) {
  return const SizedBox.shrink();
}
