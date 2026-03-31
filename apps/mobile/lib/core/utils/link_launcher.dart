import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void _showLaunchError(BuildContext? context, String message) {
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Normalizes a raw string into something [Uri.parse] can open.
///
/// - Web / social: adds `https://` when the scheme is missing (e.g. `www.…`, `instagram.com/…`).
/// - WhatsApp: `wa.me/...` → `https://wa.me/...`.
/// - Already valid: `https:`, `http:`, `tel:`, `mailto:` unchanged.
String normalizeUrlForLaunch(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';

  final lower = t.toLowerCase();
  if (lower.startsWith('tel:') ||
      lower.startsWith('mailto:') ||
      lower.startsWith('https://') ||
      lower.startsWith('http://')) {
    return t;
  }
  if (lower.startsWith('wa.me') || lower.startsWith('api.whatsapp.com')) {
    return 'https://$t';
  }
  if (lower.startsWith('www.')) {
    return 'https://$t';
  }
  // host.tld/... without scheme
  if (RegExp(
        r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z]{2,})+(/|\?|#|$)',
        caseSensitive: false,
      ).hasMatch(t)) {
    return 'https://$t';
  }
  return t;
}

/// Returns a [Uri] suitable for [launchUrl], or `null` if invalid.
Uri? parseLaunchUri(String raw) {
  final normalized = normalizeUrlForLaunch(raw);
  if (normalized.isEmpty) return null;

  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme) return null;

  final scheme = uri.scheme.toLowerCase();
  const allowed = {'https', 'http', 'tel', 'mailto'};
  if (!allowed.contains(scheme)) return null;

  return uri;
}

/// Opens [url] in the platform browser, dialer, mail client, or WhatsApp (via https).
///
/// Uses [launchUrl] (not deprecated `launch`). Does **not** rely on [canLaunchUrl]
/// alone — on Android 11+ [canLaunchUrl] often returns `false` without manifest
/// `<queries>`, which previously blocked opening.
///
/// Pass [context] to show an Arabic [SnackBar] when the link cannot be opened.
Future<void> openLink(String url, {BuildContext? context}) async {
  final uri = parseLaunchUri(url);
  if (uri == null) {
    _showLaunchError(context, 'رابط غير صالح');
    return;
  }

  try {
    var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    if (!ok && context != null && context.mounted) {
      _showLaunchError(context, 'تعذر فتح الرابط على هذا الجهاز');
    }
  } catch (_) {
    if (context != null && context.mounted) {
      _showLaunchError(context, 'حدث خطأ أثناء فتح الرابط');
    }
  }
}
