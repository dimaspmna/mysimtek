import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/fcm_service.dart';
import 'core/providers/auth_provider.dart';
import 'features/customer/providers/customer_dashboard_provider.dart';
import 'features/customer/providers/billing_provider.dart';
import 'features/customer/providers/ticket_provider.dart';
import 'features/customer/providers/complaint_provider.dart';
import 'features/customer/providers/notification_provider.dart';
import 'features/auth/providers/ota_access_provider.dart';
import 'core/providers/app_update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register WebView platform implementation.
  // Uses kIsWeb + defaultTargetPlatform (safe on all platforms, no dart:io).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  final storageService = StorageService();
  final apiService = ApiService(storageService);

  // Terapkan URL ISP yang tersimpan (jika ada)
  final savedIspId = await storageService.getIspId();
  if (savedIspId != null) {
    final isp = ApiConstants.ispList
        .cast<Map<String, String>?>()
        .firstWhere(
          (e) => e!['id'] == savedIspId,
          orElse: () => null,
        );
    if (isp != null) {
      ApiConstants.baseUrl = isp['baseUrl']!;
    }
  }

  await FcmService.initialize(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
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
        ChangeNotifierProvider(create: (_) => OtaAccessProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AppUpdateProvider(apiService)),
      ],
      child: const OfaApp(),
    ),
  );
}
