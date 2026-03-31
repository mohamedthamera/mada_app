import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../../app/router.dart';

/// يستمع لروابط `madaapp://reset-password` ويوجّه إلى شاشة إعادة التعيين.
class AuthDeepLinkListener extends StatefulWidget {
  const AuthDeepLinkListener({super.key, required this.child});

  final Widget? child;

  @override
  State<AuthDeepLinkListener> createState() => _AuthDeepLinkListenerState();
}

class _AuthDeepLinkListenerState extends State<AuthDeepLinkListener> {
  StreamSubscription<Uri>? _sub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      _handleUri(initial);
      _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
    } catch (_) {
      // app_links قد يفشل على بعض المنصات؛ نتجاهل بصمت
    }
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    if (scheme == 'madaapp' && host == 'reset-password') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        appRouter.go('/reset-password');
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
