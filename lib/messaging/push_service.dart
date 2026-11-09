import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/notification_store.dart';
import 'native_push_bridge.dart';
import 'route_parser.dart';

/// Topik broadcast untuk seluruh mahasiswa.
const String kAnnouncementTopic = 'pengumuman-kampus';

const String _channelId = 'pengumuman';
const String _channelName = 'Pengumuman Kampus';

/// Handler background WAJIB fungsi top-level dan diberi `@pragma('vm:entry-point')`.
///
/// Alasannya: di Android handler ini dijalankan pada isolate terpisah yang
/// dibuat native, sehingga Dart VM butuh entry point yang bisa dipanggil
/// tanpa instance kelas. Di dalamnya **tidak boleh** menyentuh `BuildContext`,
/// `ProviderContainer`, atau widget apa pun — isolate ini tidak punya UI.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM/background] id=${message.messageId} '
    'title=${message.notification?.title} data=${message.data}',
  );
}

/// Dari mana event push berasal.
enum PushSource {
  /// Belum ditentukan.
  unknown,

  /// Firebase Cloud Messaging (perangkat sungguhan).
  firebase,

  /// Jembatan native iOS (simulator / tanpa Firebase).
  bridge,

  /// Tidak ada sumber aktif.
  none,
}

enum PushStatus {
  /// Belum diinisialisasi.
  unknown,

  /// `google-services.json` / `GoogleService-Info.plist` belum ada dan bridge
  /// native juga tidak tersedia. Aplikasi tetap jalan normal.
  disabled,

  /// FCM aktif: izin diberikan, token terdaftar, topik di-subscribe.
  ready,

  /// Jembatan native aktif (iOS Simulator). Tiga app state bisa diuji,
  /// tetapi token FCM tidak tersedia.
  simulator,

  /// Pengguna menolak izin notifikasi.
  denied,

  /// Terjadi error lain saat inisialisasi.
  error,
}

/// Ringkasan status push untuk halaman Debug.
@immutable
class PushSnapshot {
  const PushSnapshot({
    this.status = PushStatus.unknown,
    this.source = PushSource.unknown,
    this.message,
    this.tokenPreview,
    this.topic = kAnnouncementTopic,
    this.permissionGranted = false,
    this.backendStatus,
  });

  final PushStatus status;
  final PushSource source;
  final String? message;

  /// Hanya 12 karakter pertama + "...". Token penuh tidak pernah ditampilkan
  /// maupun di-log.
  final String? tokenPreview;
  final String topic;
  final bool permissionGranted;

  /// Hasil pengiriman token ke backend (null = belum dicoba).
  final String? backendStatus;

  PushSnapshot copyWith({
    PushStatus? status,
    PushSource? source,
    String? message,
    String? tokenPreview,
    String? topic,
    bool? permissionGranted,
    String? backendStatus,
  }) {
    return PushSnapshot(
      status: status ?? this.status,
      source: source ?? this.source,
      message: message ?? this.message,
      tokenPreview: tokenPreview ?? this.tokenPreview,
      topic: topic ?? this.topic,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      backendStatus: backendStatus ?? this.backendStatus,
    );
  }
}

/// Pembungkus FCM + local notification + jembatan native iOS.
class PushService {
  PushService({FlutterLocalNotificationsPlugin? local})
    : _local = local ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _local;

  /// Satu-satunya pintu masuk notifikasi ke daftar in-app (Task: daftar
  /// notifikasi). Dipasang oleh bootstrap `main.dart` agar [PushService]
  /// tidak bergantung pada provider/UI.
  void Function(StoredNotification)? onIncoming;

  /// Status reaktif untuk halaman Debug.
  final ValueNotifier<PushSnapshot> snapshot = ValueNotifier<PushSnapshot>(
    const PushSnapshot(),
  );

  /// Rute tertunda dari klik notifikasi lokal (foreground).
  final ValueNotifier<String?> pendingRoute = ValueNotifier<String?>(null);

  /// Ringkas token supaya aman ditampilkan di layar / screenshot.
  static String? previewToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final head = token.length <= 12 ? token : token.substring(0, 12);
    return '$head...';
  }

  void updateStatus(
    PushStatus status, {
    PushSource? source,
    String? message,
  }) {
    snapshot.value = snapshot.value.copyWith(
      status: status,
      source: source,
      message: message,
    );
  }

  /// Mencatat hasil pendaftaran token ke backend agar terlihat di halaman
  /// Debug — termasuk saat gagal, supaya penyebabnya tidak tersembunyi di
  /// log saja.
  void setBackendStatus(String? value) {
    snapshot.value = snapshot.value.copyWith(backendStatus: value);
  }

  /// Menyiapkan channel + callback klik notifikasi lokal.
  ///
  /// Ini aman dipanggil walau Firebase belum dikonfigurasi.
  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      // Izin diminta eksplisit lewat [requestPermission], bukan otomatis saat
      // plugin diinisialisasi.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        pendingRoute.value = response.payload;
      },
    );

    // State *terminated*: aplikasi diluncurkan dari notifikasi, sehingga
    // `onDidReceiveNotificationResponse` tidak pernah terpanggil. Satu-satunya
    // sumber informasi adalah `getNotificationAppLaunchDetails()`. Tanpa ini,
    // tap notifikasi saat aplikasi mati hanya membuka halaman awal.
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch != null &&
        launch.didNotificationLaunchApp &&
        launch.notificationResponse?.payload != null) {
      pendingRoute.value = launch.notificationResponse!.payload;
    }

    // Android 8+ butuh channel eksplisit; tanpa ini notifikasi high-importance
    // akan turun jadi silent.
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Pemberitahuan jadwal, nilai, dan pengumuman kampus',
            importance: Importance.high,
          ),
        );
  }

  /// Meminta izin notifikasi via Firebase (iOS) dan plugin lokal (Android 13+).
  ///
  /// - iOS: `requestPermission` Firebase yang memunculkan dialog sistem.
  /// - Android 13+ (API 33): dialog `POST_NOTIFICATIONS` dimunculkan oleh
  ///   plugin local notification, bukan oleh Firebase. Karena itu kedua
  ///   pemanggilan di bawah diperlukan.
  /// - Android < 13: keduanya langsung mengembalikan `true`.
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    final fcmGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    final androidGranted = await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final granted = fcmGranted && (androidGranted ?? true);
    snapshot.value = snapshot.value.copyWith(permissionGranted: granted);
    return granted;
  }

  /// Izin lewat jembatan native iOS (tanpa Firebase).
  Future<bool> requestPermissionViaBridge(NativePushBridge bridge) async {
    final granted = await bridge.requestPermission();
    snapshot.value = snapshot.value.copyWith(permissionGranted: granted);
    return granted;
  }

  /// Izin notifikasi **tanpa** Firebase.
  ///
  /// Dipakai pada jalur `disabled`: meski push jarak jauh tidak aktif, uji
  /// notifikasi lokal tetap harus bisa dijalankan. Di Android 13+ tanpa
  /// `POST_NOTIFICATIONS`, `_local.show()` gagal diam-diam.
  Future<bool> requestLocalPermission() async {
    final androidGranted = await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosGranted = await _local
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final granted = androidGranted ?? iosGranted ?? true;
    snapshot.value = snapshot.value.copyWith(permissionGranted: granted);
    return granted;
  }

  /// Mencegah banner ganda di iOS.
  ///
  /// Tanpa ini, iOS menampilkan banner sistem **dan** local notification yang
  /// kita buat di `onMessage` — bug yang oleh codelab disebut "banner ganda".
  /// Default Firebase adalah `alert: true`, jadi harus dimatikan eksplisit.
  Future<void> configureIosForegroundPresentation() async {
    if (kIsWeb || !Platform.isIOS) return;
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  /// Ambil token saat ini, pantau rotasi token, lalu berlangganan topik.
  ///
  /// [onToken] harus benar-benar mengirim token ke backend. Kalau hanya
  /// `debugPrint`, backend akan menyimpan token basi setelah reinstall.
  ///
  /// Catatan versi: `firebase_messaging` 17 menandai `getToken()` /
  /// `onTokenRefresh` sebagai deprecated dan memperkenalkan `register()` /
  /// `onRegistered`. Keduanya masih berfungsi dan masih yang diwajibkan
  /// codelab minggu 6, jadi sementara dipakai dengan `ignore` eksplisit.
  /// Lihat `docs/ai-challenge.md` untuk alasan keputusannya.
  Future<void> initToken({
    required Future<void> Function(String token) onToken,
  }) async {
    final messaging = FirebaseMessaging.instance;

    // ignore: deprecated_member_use
    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      snapshot.value = snapshot.value.copyWith(
        tokenPreview: previewToken(token),
      );
      await onToken(token);
    }

    // Wajib ada: token berubah setelah reinstall, clear data, restore backup,
    // atau rotasi keamanan dari sisi FCM.
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen((fresh) async {
      snapshot.value = snapshot.value.copyWith(
        tokenPreview: previewToken(fresh),
      );
      await onToken(fresh);
    });

    await messaging.subscribeToTopic(kAnnouncementTopic);
  }

  Future<void> unsubscribeFromTopic() =>
      FirebaseMessaging.instance.unsubscribeFromTopic(kAnnouncementTopic);

  Future<void> resubscribeToTopic() =>
      FirebaseMessaging.instance.subscribeToTopic(kAnnouncementTopic);

  /// Menampilkan notifikasi lokal.
  ///
  /// Dipakai untuk dua hal:
  /// 1. pesan FCM saat aplikasi foreground (sistem tidak menampilkan banner
  ///    otomatis pada state ini),
  /// 2. tombol "Uji notifikasi lokal" di halaman Home/Debug.
  Future<void> showLocal({
    required int id,
    required String title,
    required String body,
    required String route,
  }) async {
    // Suara: di Android, channel `Importance.high` (initLocalNotifications)
    // sudah memutar suara default sistem — `sound` sengaja TIDAK di-set
    // eksplisit karena `RawResourceAndroidNotificationSound('default')`
    // berisiko menunjuk resource app yang salah. Di iOS (v22), param
    // `playSound` lama tidak ada lagi; `sound` yang dibiarkan null berarti
    // suara default sistem — jadi keduanya sengaja dibiarkan default.
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Pemberitahuan jadwal, nilai, dan pengumuman',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: route,
    );
    // Setiap notifikasi yang ditampilkan ikut masuk daftar in-app.
    onIncoming?.call(
      StoredNotification(
        id: '$id',
        title: title,
        body: body,
        route: route,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Menghapus banner notifikasi lokal dari shade (dipanggil saat item
  /// daftar dibaca, supaya banner yang masih tertinggal ikut hilang).
  Future<void> dismissLocal(int id) async {
    if (id <= 0) return;
    await _local.cancel(id: id);
  }

  /// Foreground + klik dari background (jalur Firebase).
  void listenForeground({required void Function(String route) go}) {
    // Foreground: banner TIDAK muncul otomatis -> tampilkan manual.
    // (`showLocal` sendiri memanggil onIncoming.)
    FirebaseMessaging.onMessage.listen((message) async {
      final route = routeFromMessage(message.data);
      await showLocal(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman',
        body: message.notification?.body ?? '',
        route: route,
      );
    });

    // Background: banner ditampilkan sistem, klik masuk ke sini.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Pesan diterima saat background: masuk daftar lalu buka rute.
      onIncoming?.call(_fromRemote(message));
      go(routeFromMessage(message.data));
    });
  }

  /// Konversi RemoteMessage ke item daftar (dipakai state background/
  /// terminated, yang tidak melewati [showLocal]).
  StoredNotification _fromRemote(RemoteMessage m) => StoredNotification(
        id: '${m.hashCode.abs()}',
        title: m.notification?.title ?? 'Pengumuman',
        body: m.notification?.body ?? '',
        route: routeFromMessage(m.data),
        createdAt: DateTime.now(),
      );

  /// Foreground + klik dari background (jalur jembatan native iOS).
  ///
  /// Perilakunya dibuat identik dengan [listenForeground]: foreground
  /// ditampilkan manual lewat local notification, klik diteruskan ke router.
  void listenBridge(
    NativePushBridge bridge, {
    required void Function(String route) go,
  }) {
    bridge.events().listen((event) async {
      switch (event.type) {
        case BridgePushEventType.message:
          await showLocal(
            id: event.payload.hashCode,
            title: event.payload.title.isEmpty
                ? 'Pengumuman'
                : event.payload.title,
            body: event.payload.body,
            route: routeFromMessage(event.payload.data),
          );
        case BridgePushEventType.opened:
          // Pesan diterima saat background: masuk daftar lalu buka rute.
          onIncoming?.call(
            StoredNotification(
              id: '${event.payload.hashCode.abs()}',
              title:
                  event.payload.title.isEmpty
                      ? 'Pengumuman'
                      : event.payload.title,
              body: event.payload.body,
              route: routeFromMessage(event.payload.data),
              createdAt: DateTime.now(),
            ),
          );
          go(routeFromMessage(event.payload.data));
        case BridgePushEventType.background:
          // Data-only di background: sistem tidak menampilkan apa pun.
          debugPrint('[push/bridge] data-only: ${event.payload.data}');
      }
    });
  }

  /// Terminated: aplikasi dibuka dari notifikasi (jalur Firebase).
  ///
  /// Harus dipanggil **setelah** router siap, kalau tidak `go()` akan
  /// menabrak navigator yang belum punya halaman.
  Future<void> handleTerminated(void Function(String route) go) async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Aplikasi diluncurkan dari notifikasi: masuk daftar lalu buka rute.
      onIncoming?.call(_fromRemote(initial));
      go(routeFromMessage(initial.data));
    }
    _flushPendingRoute(go);
  }

  /// Terminated: aplikasi dibuka dari notifikasi (jalur jembatan native).
  Future<void> handleBridgeInitial(
    NativePushBridge bridge, {
    required void Function(String route) go,
  }) async {
    final initial = await bridge.getInitialPayload();
    if (initial != null) {
      onIncoming?.call(
        StoredNotification(
          id: '${initial.hashCode.abs()}',
          title: initial.title.isEmpty ? 'Pengumuman' : initial.title,
          body: initial.body,
          route: routeFromMessage(initial.data),
          createdAt: DateTime.now(),
        ),
      );
      go(routeFromMessage(initial.data));
    }
    _flushPendingRoute(go);
  }

  /// Menyambungkan klik notifikasi lokal ke navigator.
  ///
  /// Rute bisa sudah terisi **sebelum** router siap — persis kasus state
  /// terminated, saat payload dibaca di [initLocalNotifications] dan router
  /// belum punya navigator. Karena itu selain memasang listener, nilai yang
  /// sudah ada langsung di-flush.
  void attachNavigator(void Function(String route) go) {
    pendingRoute.addListener(() => _flushPendingRoute(go));
    _flushPendingRoute(go);
  }

  void _flushPendingRoute(void Function(String route) go) {
    final route = pendingRoute.value;
    if (route == null) return;
    pendingRoute.value = null;
    go(route);
  }

  /// Platform saat ini, dipakai saat melaporkan token ke backend.
  static String get platformName {
    if (kIsWeb) return 'web';
    return Platform.isIOS ? 'ios' : 'android';
  }

  void dispose() {
    snapshot.dispose();
    pendingRoute.dispose();
  }
}
