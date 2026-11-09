import 'package:flutter/services.dart';

/// Payload push yang sudah dinormalkan oleh `AppDelegate.swift`.
///
/// Bentuknya sengaja menyerupai `RemoteMessage` FCM supaya lapisan di atasnya
/// tidak perlu tahu dari mana pesan berasal.
class BridgePushPayload {
  const BridgePushPayload({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;

  static BridgePushPayload fromMap(Map<dynamic, dynamic> map) {
    final rawData = map['data'];
    return BridgePushPayload(
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      data: rawData is Map
          ? rawData.map((key, value) => MapEntry('$key', value))
          : const <String, dynamic>{},
    );
  }
}

/// Jenis event dari jembatan native.
enum BridgePushEventType {
  /// Pesan masuk saat aplikasi foreground.
  message,

  /// Pengguna menekan notifikasi.
  opened,

  /// Pesan data-only saat aplikasi background.
  background,
}

class BridgePushEvent {
  const BridgePushEvent({required this.type, required this.payload});

  final BridgePushEventType type;
  final BridgePushPayload payload;
}

/// Klien untuk jembatan push native iOS.
///
/// Hanya aktif bila `AppDelegate.swift` melaporkan bahwa Firebase tidak
/// dikonfigurasi. Dipakai untuk menguji tiga app state di iOS Simulator,
/// tempat APNs token tidak pernah tersedia.
class NativePushBridge {
  const NativePushBridge({
    this._method = const MethodChannel('campus_notify/push'),
    this._events = const EventChannel('campus_notify/push_events'),
  });

  final MethodChannel _method;
  final EventChannel _events;

  /// `true` bila bridge aktif (Firebase tidak dikonfigurasi).
  Future<bool> isBridgeMode() async {
    try {
      return await _method.invokeMethod<bool>('isBridgeMode') ?? false;
    } on MissingPluginException {
      // Platform selain iOS, atau AppDelegate lama.
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Meminta izin notifikasi lewat `UNUserNotificationCenter`.
  Future<bool> requestPermission() async {
    try {
      return await _method.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Payload yang membuka aplikasi dari state terminated.
  Future<BridgePushPayload?> getInitialPayload() async {
    try {
      final map = await _method.invokeMapMethod<dynamic, dynamic>(
        'getInitialPayload',
      );
      if (map == null) return null;
      return BridgePushPayload.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Stream event dari native.
  Stream<BridgePushEvent> events() {
    return _events.receiveBroadcastStream().map((raw) {
      final map = (raw as Map).cast<dynamic, dynamic>();
      final payload = BridgePushPayload.fromMap(
        (map['payload'] as Map).cast<dynamic, dynamic>(),
      );
      final type = switch (map['event'] as String?) {
        'opened' => BridgePushEventType.opened,
        'background' => BridgePushEventType.background,
        _ => BridgePushEventType.message,
      };
      return BridgePushEvent(type: type, payload: payload);
    });
  }
}
