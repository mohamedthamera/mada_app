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
  String href = '';
  void setAttribute(String name, String value) {}
  void click() {}
}
