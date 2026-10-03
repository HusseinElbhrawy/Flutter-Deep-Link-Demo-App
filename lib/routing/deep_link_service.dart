import 'dart:async';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

// Replace this together with the native Android/iOS domain configuration.
const deepLinkHost = 'example.com';
const demoLinkScheme = 'deep-link-demo';
const demoLinkHost = 'app';

/// Converts an allowed external URL into an internal router location.
/// Unsupported URLs leave the current screen unchanged.
String? deepLinkLocation(Uri uri) {
  final isWebLink =
      uri.scheme == 'https' && uri.host == deepLinkHost && uri.port == 443;
  final isDemoLink =
      uri.scheme == demoLinkScheme &&
      uri.host == demoLinkHost &&
      !uri.hasPort;
  if ((!isWebLink && !isDemoLink) || uri.userInfo.isNotEmpty) {
    return null;
  }

  final path = uri.path.isEmpty ? '/' : uri.path;
  final isStaticRoute = path == '/' || path == '/profile' || path == '/promo';
  var isProductRoute = false;
  try {
    Uri.decodeQueryComponent(uri.query);
    final segments = uri.pathSegments;
    isProductRoute =
        path.startsWith('/products/') &&
        segments.length == 2 &&
        segments[0] == 'products' &&
        segments[1].trim().isNotEmpty &&
        !segments[1].contains('/');
  } on FormatException {
    return null;
  }

  if (!isStaticRoute && !isProductRoute) return null;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

class DeepLinkService {
  final GoRouter router;
  final Stream<Uri> _linkStream;
  StreamSubscription<Uri>? _subscription;

  DeepLinkService(this.router, {Stream<Uri>? linkStream})
    : _linkStream = linkStream ?? AppLinks().uriLinkStream;

  Future<void> initialize() async {
    // app_links includes the initial link; do not also navigate via getInitialLink.
    _subscription ??= _linkStream.listen(
      _handleUri,
      onError: (error) => log('Deep link error: $error'),
      onDone: () => log('Deep link stream closed'),
      cancelOnError: false,
    );
  }

  void _handleUri(Uri uri) {
    final location = deepLinkLocation(uri);
    if (location == null) {
      log('Ignored unsupported deep link');
      return;
    }

    router.go(location);
  }

  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
