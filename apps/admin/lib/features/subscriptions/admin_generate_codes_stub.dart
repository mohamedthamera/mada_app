// Stub for dart:html when running on non-web platforms (iOS, Android, macOS, Windows).
// Only used so the conditional import resolves; _downloadCSV uses this only when kIsWeb is true (web).

class Blob {
  Blob(List<dynamic> list);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) =>
      throw UnsupportedError('dart:html only on web');
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  void setAttribute(String name, String value) {}
  void click() {}
}
