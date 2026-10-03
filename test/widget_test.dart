import 'dart:async';

import 'package:deep_link_demo_app/app/app.dart';
import 'package:deep_link_demo_app/routing/app_router.dart';
import 'package:deep_link_demo_app/routing/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts on the home screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to the Home Screen!'), findsOneWidget);
  });

  testWidgets('Initial link received before mounting opens the product', (
    tester,
  ) async {
    final router = createRouter();
    final links = StreamController<Uri>(sync: true);
    final service = DeepLinkService(router, linkStream: links.stream);
    addTearDown(() async {
      await service.dispose();
      await links.close();
      router.dispose();
    });

    await service.initialize();
    links.add(Uri.parse('https://example.com/products/42'));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Product ID: 42'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Warm links preserve queries and unsupported links are ignored', (
    tester,
  ) async {
    final router = createRouter();
    final links = StreamController<Uri>();
    final service = DeepLinkService(router, linkStream: links.stream);
    addTearDown(() async {
      await service.dispose();
      await links.close();
      router.dispose();
    });

    await service.initialize();
    // A second call must not create another subscription.
    await service.initialize();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    links.add(Uri.parse('https://example.com/promo?code=SUMMER%2020'));
    await tester.pumpAndSettle();
    expect(find.text('Promo code: SUMMER 20'), findsOneWidget);

    links.add(Uri.parse('deep-link-demo://app/products/42'));
    await tester.pumpAndSettle();
    expect(find.text('Product ID: 42'), findsOneWidget);

    links.add(Uri.parse('deep-link-demo://app/promo?code=SUMMER%2020'));
    await tester.pumpAndSettle();
    expect(find.text('Promo code: SUMMER 20'), findsOneWidget);

    for (final url in [
      'https://example.com/unknown',
      'https://untrusted.example/products/99',
      'https://example.com/products/',
      'https://example.com/products/%FF',
      'https://example.com/promo?code=%FF',
    ]) {
      links.add(Uri.parse(url));
      await tester.pumpAndSettle();
      expect(find.text('Promo code: SUMMER 20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    links.addError(StateError('Simulated platform stream error'));
    links.add(Uri.parse('https://example.com/promo'));
    await tester.pumpAndSettle();
    expect(find.text('Promo code: No promo'), findsOneWidget);

    links.add(Uri.parse('https://example.com/profile'));
    await tester.pumpAndSettle();
    expect(find.byType(Placeholder), findsOneWidget);

    links.add(Uri.parse('https://example.com/'));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen'), findsOneWidget);

    // Cancellation schedules work outside the widget test fake clock.
    await tester.runAsync(service.dispose);
    links.add(Uri.parse('https://example.com/products/99'));
    await tester.pumpAndSettle();
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
