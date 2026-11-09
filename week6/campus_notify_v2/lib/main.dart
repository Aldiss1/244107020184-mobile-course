import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/native_push_bridge.dart';
import 'data/push_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/push_provider.dart';
import 'presentation/providers/router_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase sengaja diinisialisasi dengan guard: tanpa `google-services.json`
  // (Android) atau `GoogleService-Info.plist` (iOS), aplikasi tetap harus bisa
  // dijalankan untuk menguji auth, secure storage, router, dan push lewat
  // jembatan native iOS.
  FirebaseBoot boot;
  try {
    await Firebase.initializeApp();
    boot = const FirebaseBoot(ready: true);
  } catch (error) {
    boot = FirebaseBoot(ready: false, error: error.toString());
    debugPrint('[Firebase] belum dikonfigurasi: $error');
  }

  runApp(
    ProviderScope(
      overrides: [firebaseBootProvider.overrideWithValue(boot)],
      child: const CampusNotifyApp(),
    ),
  );
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    // Ditunda satu frame supaya GoRouter sudah terpasang sebelum
    // getInitialMessage() memanggil go().
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapPush());
  }

  Future<void> _bootstrapPush() async {
    final push = ref.read(pushServiceProvider);
    final router = ref.read(routerProvider);
    final boot = ref.read(firebaseBootProvider);

    await push.initLocalNotifications();

    // Daftar notifikasi in-app: muat sisa dari file, lalu sambungkan
    // setiap notifikasi yang datang (tombol uji, FCM foreground, klik
    // dari background/terminated) ke list + badge.
    await ref.read(notificationsProvider.notifier).init();
    push.onIncoming = (n) =>
        unawaited(ref.read(notificationsProvider.notifier).add(n));

    push.attachNavigator(router.go);

    if (boot.ready) {
      await _bootstrapFirebase(push, router);
      return;
    }

    final bridge = const NativePushBridge();
    if (await bridge.isBridgeMode()) {
      await _bootstrapBridge(push, bridge, router);
      return;
    }

    push.updateStatus(
      PushStatus.disabled,
      source: PushSource.none,
      message:
          'Tambahkan google-services.json (Android) atau '
          'GoogleService-Info.plist (iOS) lalu jalankan ulang aplikasi. '
          'Auth, secure storage, dan notifikasi lokal tetap bisa diuji.',
    );

    // Push jarak jauh mati, tetapi notifikasi lokal masih bisa didemokan —
    // asalkan izinnya diminta. Di Android 13+ izin ini wajib.
    await push.requestLocalPermission();
  }

  /// Jalur produksi: Firebase Cloud Messaging.
  Future<void> _bootstrapFirebase(
    PushService push,
    GoRouter router,
  ) async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await push.configureIosForegroundPresentation();

      final granted = await push.requestPermission();
      if (!granted) {
        push.updateStatus(
          PushStatus.denied,
          source: PushSource.firebase,
          message: 'Aktifkan izin notifikasi dari pengaturan aplikasi.',
        );
        return;
      }

      push.listenForeground(go: router.go);

      final registrar = ref.read(deviceRegistrarProvider);
      await push.initToken(
        onToken: (token) async {
          // Token BENAR-BENAR dikirim ke backend, bukan hanya di-print.
          // Endpoint bisa diarahkan lewat --dart-define=DEVICES_URL=...
          final result = await registrar.register(
            token: token,
            platform: PushService.platformName,
          );
          push.setBackendStatus(result.shortLabel);
          if (!result.ok) {
            debugPrint(
              '[FCM] token gagal didaftarkan ke ${registrar.url}: '
              '${result.label}',
            );
          } else {
            debugPrint('[FCM] token terdaftar di ${registrar.url}');
          }
        },
      );

      await push.handleTerminated(router.go);
      push.updateStatus(PushStatus.ready, source: PushSource.firebase);
    } catch (error) {
      push.updateStatus(
        PushStatus.error,
        source: PushSource.firebase,
        message: error.toString(),
      );
      debugPrint('[FCM] inisialisasi gagal: $error');
    }
  }

  /// Jalur iOS Simulator: APNs token tidak pernah ada, jadi Firebase tidak
  /// bisa memberi FCM token. `AppDelegate.swift` meneruskan payload
  /// `simctl push` langsung ke Dart.
  Future<void> _bootstrapBridge(
    PushService push,
    NativePushBridge bridge,
    GoRouter router,
  ) async {
    final granted = await push.requestPermissionViaBridge(bridge);
    if (!granted) {
      push.updateStatus(
        PushStatus.denied,
        source: PushSource.bridge,
        message: 'Aktifkan izin notifikasi di Settings > Campus Notify.',
      );
      return;
    }

    push.listenBridge(bridge, go: router.go);
    await push.handleBridgeInitial(bridge, go: router.go);

    push.updateStatus(
      PushStatus.simulator,
      source: PushSource.bridge,
      message:
          'Mode simulator: payload dikirim via `xcrun simctl push`. '
          'Token FCM tidak tersedia karena APNs token tidak diterbitkan '
          'untuk Simulator.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
