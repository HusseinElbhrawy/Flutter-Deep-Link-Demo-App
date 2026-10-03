import 'package:flutter/material.dart';

class PromoScreen extends StatelessWidget {
  final String? promoCode;
  const PromoScreen({required this.promoCode, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotion')),
      body: Center(child: Text('Promo code: ${promoCode ?? "No promo"}', style: const TextStyle(fontSize: 24))),
    );
  }
}
