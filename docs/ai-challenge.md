# AI Prompt Challenge — Minggu 6

Folder ini menyimpan jejak penggunaan AI sesuai aturan codelab: prompt,
output awal, daftar perbaikan manual, dan alasan teknis.

---

## 1. Prompt yang dipakai

```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

---

## 2. Ringkasan output awal AI

Draf pertama mengikuti struktur codelab hampir persis:

- `TokenStore` dengan `flutter_secure_storage` — **diterima apa adanya**.
- `buildApiClient` dengan interceptor 401 → refresh → retry — **diterima,
  dengan satu perbaikan** (lihat #3).
- `PushService` berisi `requestPermission`, `getToken`, `onTokenRefresh`,
  `onMessage`, `onMessageOpenedApp`, `getInitialMessage` — **struktur
  diterima, detail API tidak**.
- Background handler sudah memakai `@pragma('vm:entry-point')` dan top-level —
  **diterima**.

---

## 3. Perbaikan manual yang dilakukan

### 3.1 API `flutter_local_notifications` 22 berubah (breaking)

Draf memakai bentuk lama:

```dart
// SALAH pada v22
await _local.initialize(
  const InitializationSettings(android: android, iOS: ios),
  onDidReceiveNotificationResponse: ...,
);

await _local.show(
  id, title, body, const NotificationDetails(...),
  payload: route,
);
```

Pada v22 `initialize()` dan `show()` memakai *named parameters*:

```dart
// BENAR
await _local.initialize(
  settings: const InitializationSettings(android: android, iOS: darwin),
  onDidReceiveNotificationResponse: ...,
);

await _local.show(
  id: id,
  title: title,
  body: body,
  notificationDetails: const NotificationDetails(...),
  payload: route,
);
```

**Alasan:** mengikuti signature package yang benar-benar terpasang, bukan
contoh di internet. Diverifikasi lewat `flutter analyze` (gagal kompilasi bila
salah).

### 3.2 Izin Android 13+ tidak ditangani draf

Draf hanya memanggil `FirebaseMessaging.instance.requestPermission()`. Di
Android 13+ itu **tidak** memunculkan dialog `POST_NOTIFICATIONS` — dialog
muncul dari plugin local notification. Perbaikannya:

```dart
final androidGranted = await _local
    .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >()
    ?.requestNotificationsPermission();
```

Juga ditambahkan di `AndroidManifest.xml`:
`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.

**Alasan:** tanpa ini, di Android 13+ notifikasi foreground tidak akan muncul
sama sekali walau kode banner-nya benar.

### 3.3 Channel notifikasi Android tidak dibuat

Draf memakai `AndroidNotificationDetails('pengumuman', ...)` tetapi tidak
pernah memanggil `createNotificationChannel`. Di Android 8+ channel tanpa
deklarasi akan memakai importance default (rendah) sehingga banner bisa tidak
tampil. Perbaikan: channel dibuat di `initLocalNotifications()` **dan**
didaftarkan sebagai `default_notification_channel_id` di manifest, supaya
notifikasi background dari sistem juga masuk ke channel yang sama.

### 3.4 `onTokenRefresh` hanya `print`

Draf menulis:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen(debugPrint);
```

Ini melanggar checklist: backend akan menyimpan token basi setelah reinstall.
Perbaikan: `initToken({required Future<void> Function(String) onToken})`
mewajibkan callback yang benar-benar `POST /devices`, dan hanya preview token
terpotong yang disimpan untuk UI.

### 3.5 Interceptor berpotensi loop

Draf mengulang request tanpa penanda. Bila backend tetap membalas 401, request
di-retry selamanya. Perbaikan: `requestOptions.extra['retried_after_refresh']`.

### 3.6 `getInitialMessage()` dipanggil sebelum router siap

Draf memanggil `handleTerminated(router.go)` di dalam `main()` sebelum
`runApp`. Perbaikan: dipanggil setelah frame pertama
(`addPostFrameCallback`) dan setelah `routerProvider` terbentuk.

### 3.7 Klik notifikasi lokal (foreground) tidak pernah dinavigasikan

Draf menyimpan `pendingDeepLink` tetapi tidak ada yang membacanya. Perbaikan:
`ValueNotifier<String?> pendingRoute` + `attachNavigator(go)`.

### 3.8 Tidak ada guard saat Firebase belum dikonfigurasi

Draf langsung `await Firebase.initializeApp()` sehingga aplikasi crash bila
`google-services.json` belum ada. Perbaikan: `try/catch` + `FirebaseBoot` +
status `PushStatus.disabled`, sehingga auth/secure storage/routing tetap bisa
didemokan.

---

## 4. Hal yang **ditolak** dari draf AI

| Draf | Alasan ditolak |
|---|---|
| Menyimpan token di `SharedPreferences` "agar lebih mudah" | Tidak terenkripsi. Melanggar prinsip dasar keamanan mobile. |
| Menampilkan token penuh di halaman Debug | Screenshot laporan masuk repository publik. Diganti preview 12 karakter. |
| `debugPrint(token)` di `onTokenRefresh` | Token bocor ke logcat, bisa terbaca `adb logcat`. |
| Background handler sebagai method kelas | Isolate terpisah tidak bisa memanggil method instance. |
| Navigasi dari background handler | Tidak ada `BuildContext` di isolate itu. Navigasi hanya saat klik. |

---

## 5. Catatan versi: `getToken` / `onTokenRefresh` deprecated

`firebase_messaging` 17.0.1 menandai:

```dart
@Deprecated('Use register() and onRegistered instead.')
Future<String?> getToken({...});

@Deprecated('Use onRegistered instead.')
Stream<String> get onTokenRefresh;
```

Penggantinya, `register()` + `onRegistered`, mengeluarkan **Firebase
Installation ID (FID)** — bukan registration token FCM klasik. Codelab minggu
6 secara eksplisit mensyaratkan `getToken` + `onTokenRefresh` sebagai bukti
pemahaman token lifecycle, sehingga keduanya dipertahankan dengan
`// ignore: deprecated_member_use` dan alasan tertulis di kode.

Keputusan ini boleh berbeda dari saran AI selama ada argumen teknis — itulah
yang dicatat di sini. Bila target produksi, migrasi ke `register()` /
`onRegistered` disarankan agar tidak tertinggal dari SDK.

---

## 6. Keputusan lingkungan uji: iOS Simulator + jembatan native

Kendala nyata di mesin pengembangan:

| Jalur | Status |
|---|---|
| Android emulator + FCM asli | Android SDK belum terpasang saat implementasi |
| iPhone fisik + FCM asli | Butuh Apple Developer Program (99 USD/tahun) untuk entitlement `aps-environment` |
| iOS Simulator | APNs token tidak pernah diterbitkan → `getToken()` melempar `apns-token-not-set` |

Karena codelab menilai **bukti perilaku**, bukan sekadar kode, dipilih jalan
tengah: `AppDelegate.swift` meneruskan payload `xcrun simctl push` langsung ke
Dart lewat `EventChannel`, dengan bentuk yang sama seperti `RemoteMessage`.

Yang **ditolak** dari pendekatan ini adalah mengklaim token lifecycle lulus.
`getToken`, `onTokenRefresh`, dan `subscribeToTopic` semuanya melewati
`_APNSTokenCheck()` di `method_channel_messaging.dart`, sehingga mustahil
berhasil di simulator. Bagian itu dinyatakan belum teruji di README dan harus
dilengkapi di Android/perangkat fisik.

Alasan teknis memilih bridge native, bukan mock di Dart:

- Mock di Dart tidak menguji jalur native (`UNUserNotificationCenter`,
  `getInitialMessage`, pembukaan app dari terminated). Yang diuji hanya UI.
- Bridge memakai jalur yang **sama** dengan produksi sampai batas
  `AppDelegate`, sehingga bug seperti klik yang tidak menavigasi tetap
  tertangkap.
- Bridge menonaktifkan diri otomatis bila `GoogleService-Info.plist` ada,
  jadi tidak ada risiko dua sumber event di build produksi.

Alternatif yang dipertimbangkan dan ditolak: menambahkan
`FirebaseOptions` dummy lalu berharap `onMessage` menyala. Itu gagal karena
`_APNSTokenCheck()` dipanggil sebelum `getToken`, dan `onMessage` untuk pesan
`notification` di iOS bergantung pada APNs registration yang tidak ada.

---

## 7. Verifikasi akhir

```
$ flutter analyze
No issues found!

$ flutter test
00:00 +12: All tests passed!
```

Checklist AI Verification (dari codelab):

- [x] Background handler top-level + `@pragma('vm:entry-point')`
- [x] `onTokenRefresh` mengirim token ke backend (bukan `print`)
- [x] Foreground memakai local notification manual
- [ ] Klik dari 3 state masuk ke rute yang benar — **butuh pengujian di
      perangkat/simulator**, lihat tabel di `README.md`
- [x] Token/secret tidak di-hardcode dan tidak di-log penuh

Catatan: pada jalur jembatan iOS, `onTokenRefresh` tidak berlaku karena token
tidak terbit di simulator. Implementasinya tetap ada dan terpakai begitu
Firebase aktif.

---

## 8. Struktur bukti pengujian

| Artefak | Isi |
|---|---|
| `tool/sim_push.sh` | Pengirim payload + screenshot otomatis |
| `tool/payloads/announcement.apns` | `notification` + `data.route` untuk 3 app state |
| `tool/payloads/data_only.apns` | `content-available`, tanpa `alert` |
| `tool/payloads/malformed.apns` | Tanpa `route`/`id`, menguji fallback ke `/` |
| `screenshots/*.png` | Bukti visual tiap state (diisi setelah pengujian) |
| `README.md` §Tabel pengujian | Hasil per state + keterbatasan simulator |
