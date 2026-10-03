import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/products/product_details_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/promo/promo_screen.dart';

final router = createRouter();

GoRouter createRouter() => GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/products/:id',
      builder: (_, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailsScreen(productId: productId);
      },
    ),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: '/promo',
      builder: (_, state) {
        final code = state.uri.queryParameters['code'];
        return PromoScreen(promoCode: code);
      },
    ),
  ],
);
