import 'package:dio/dio.dart';

/// نتيجة تنزيل PDF إلى ملف مؤقت (موبايل فقط) — بدون استيراد `dart:io` في الشاشة.
class BookPdfLoadResult {
  const BookPdfLoadResult({
    required this.localFileRef,
    required this.headers,
    this.statusCode,
  });

  /// على Android/iOS: [dart:io.File].
  final Object localFileRef;
  final Headers headers;
  final int? statusCode;
}
