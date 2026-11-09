import Flutter
import UIKit
import UserNotifications

/// Jembatan push untuk lingkungan tanpa Firebase — khususnya iOS Simulator.
///
/// Kenapa ini ada: Firebase Cloud Messaging menuntut APNs token, dan APNs
/// token tidak pernah diterbitkan untuk Simulator. Tanpa jembatan ini,
/// `getToken()` melempar `apns-token-not-set` dan `onMessage` tidak pernah
/// menyala, sehingga tiga app state mustahil dibuktikan di simulator.
///
/// Jembatan ini menangkap payload yang dikirim lewat
/// `xcrun simctl push <udid> <bundle-id> payload.apns` dan meneruskannya ke
/// Dart dengan bentuk yang sama seperti `RemoteMessage` FCM:
///
///     { "title": ..., "body": ..., "data": { "route": ..., "id": ... } }
///
/// Bila `GoogleService-Info.plist` ada di bundle, jembatan ini menonaktifkan
/// diri dan menyerahkan segalanya ke `firebase_messaging`, supaya tidak ada
/// dua sumber event yang saling menimpa.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler {
  private static let eventChannelName = "campus_notify/push_events"
  private static let methodChannelName = "campus_notify/push"

  private var eventSink: FlutterEventSink?

  /// Payload notifikasi yang membuka aplikasi dari state terminated.
  ///
  /// Tipe kuncinya `AnyHashable` karena begitulah `UNNotification` dan
  /// `launchOptions` memberi `userInfo` mentah dari APNs.
  private var pendingInitial: [AnyHashable: Any]?

  /// Firebase dianggap aktif hanya bila plist konfigurasinya ikut ter-bundle.
  private var isFirebaseConfigured: Bool {
    Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Aplikasi dibuka dengan menekan notifikasi saat terminated.
    if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      pendingInitial = remote
    }

    if !isFirebaseConfigured {
      UNUserNotificationCenter.current().delegate = self
      application.registerForRemoteNotifications()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    let methodChannel = FlutterMethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "isBridgeMode":
        result(!self.isFirebaseConfigured)
      case "requestPermission":
        self.requestPermission { granted in
          result(granted)
        }
      case "getInitialPayload":
        let payload = self.pendingInitial
        self.pendingInitial = nil
        result(payload.map { Self.normalize($0) })
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: Self.eventChannelName,
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - Izin notifikasi

  private func requestPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, _ in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Foreground: sistem sengaja TIDAK menampilkan apa pun, meniru perilaku
  /// FCM pada state foreground. Dart yang menampilkan banner lewat
  /// `flutter_local_notifications`, sehingga jalur kode yang diuji sama
  /// persis dengan jalur produksi.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if isFirebaseConfigured {
      super.userNotificationCenter(
        center,
        willPresent: notification,
        withCompletionHandler: completionHandler
      )
      return
    }

    emit(event: "message", userInfo: notification.request.content.userInfo)
    completionHandler([])
  }

  /// Klik notifikasi (background maupun terminated yang sudah punya sink).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if isFirebaseConfigured {
      super.userNotificationCenter(
        center,
        didReceive: response,
        withCompletionHandler: completionHandler
      )
      return
    }

    emit(event: "opened", userInfo: response.notification.request.content.userInfo)
    completionHandler()
  }

  /// Pesan data-only yang diterima saat aplikasi di background.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if isFirebaseConfigured {
      super.application(
        application,
        didReceiveRemoteNotification: userInfo,
        fetchCompletionHandler: completionHandler
      )
      return
    }

    emit(event: "background", userInfo: userInfo)
    completionHandler(.newData)
  }

  // MARK: - Helper

  private func emit(event: String, userInfo: [AnyHashable: Any]) {
    let payload = Self.normalize(userInfo)
    guard let sink = eventSink else {
      // Belum ada listener Dart (mis. aplikasi baru dibuka dari notifikasi).
      pendingInitial = userInfo
      return
    }
    sink(["event": event, "payload": payload])
  }

  /// Menyamakan bentuk payload APNs mentah dengan `RemoteMessage` FCM.
  ///
  /// Aturan `data` mengikuti `firebase_messaging`: semua key top-level
  /// kecuali `aps`, `gcm.*`, dan `google.*`.
  private static func normalize(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
    var data: [String: Any] = [:]
    for (rawKey, value) in userInfo {
      guard let key = rawKey as? String else { continue }
      if key == "aps" || key.hasPrefix("gcm.") || key.hasPrefix("google.") {
        continue
      }
      data[key] = value
    }

    var title = ""
    var body = ""
    if let aps = userInfo["aps"] as? [String: Any] {
      if let alert = aps["alert"] as? [String: Any] {
        title = alert["title"] as? String ?? ""
        body = alert["body"] as? String ?? ""
      } else if let alert = aps["alert"] as? String {
        body = alert
      }
    }

    return ["title": title, "body": body, "data": data]
  }
}
