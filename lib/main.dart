import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'app.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/providers/auth_provider.dart';
import 'features/customer/providers/customer_dashboard_provider.dart';
import 'features/customer/providers/billing_provider.dart';
import 'features/customer/providers/ticket_provider.dart';
import 'features/customer/providers/complaint_provider.dart';
import 'features/customer/providers/notification_provider.dart';
import 'features/teknisi/providers/teknisi_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register WebView platform implementation.
  // Uses kIsWeb + defaultTargetPlatform (safe on all platforms, no dart:io).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  final storageService = StorageService();
  final apiService = ApiService(storageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerDashboardProvider(apiService),
        ),
        ChangeNotifierProvider(create: (_) => BillingProvider(apiService)),
        ChangeNotifierProvider(create: (_) => TicketProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ComplaintProvider(apiService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiService)),
        ChangeNotifierProvider(create: (_) => TeknisiProvider(apiService)),
      ],
      child: const MySimtekApp(),
    ),
  );
}
