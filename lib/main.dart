import 'package:deep_link_demo_app/app/app.dart';
import 'package:deep_link_demo_app/routing/app_router.dart';
import 'package:deep_link_demo_app/routing/deep_link_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deepLinkService = DeepLinkService(router);
  await deepLinkService.initialize();
  runApp(const MyApp());
}
