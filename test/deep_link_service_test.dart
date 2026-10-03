import 'package:deep_link_demo_app/routing/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final accepted = {
    'https://example.com': '/',
    'https://example.com/': '/',
    'https://example.com:443/profile': '/profile',
    'https://example.com/products/42': '/products/42',
    'https://example.com/products/sku-42': '/products/sku-42',
    'https://example.com/promo?code=SUMMER20': '/promo?code=SUMMER20',
    'https://example.com/promo?code=A%26B&source=email': '/promo?code=A%26B&source=email',
    'https://example.com/profile#section': '/profile',
    'deep-link-demo://app/': '/',
    'deep-link-demo://app/products/42': '/products/42',
    'deep-link-demo://app/promo?code=SUMMER20': '/promo?code=SUMMER20',
  };
  for (final entry in accepted.entries) {
    test('Maps ${entry.key}', () {
      expect(deepLinkLocation(Uri.parse(entry.key)), entry.value);
    });
  }

  for (final url in [
    'http://example.com/products/42',
    'demo://example.com/products/42',
    'deep-link-demo://wrong-host/promo',
    'deep-link-demo://app:8080/promo',
    'deep-link-demo://user@app/promo',
    '/products/42',
    'https://example.com.evil.test/products/42',
    'https://www.example.com/products/42',
    'https://example.com:8443/products/42',
    'https://user@example.com/products/42',
    'https://example.com/unknown',
    'https://example.com/products',
    'https://example.com/products/',
    'https://example.com/products/42/reviews',
    'https://example.com/products/%20',
    'https://example.com/products/a%2Fb',
    'https://example.com/products/%FF',
    'https://example.com/promo?code=%FF',
    'https://example.com/profile/',
  ]) {
    test('Ignores $url', () {
      expect(deepLinkLocation(Uri.parse(url)), isNull);
    });
  }
}
