# ADR-004: Dua jalur push — FCM bila terkonfigurasi, jembatan native untuk iOS Simulator

## Status
Accepted

## Date
2026-11-09

## Context
Codelab mensyaratkan pengujian tiga app state (foreground, background,
terminated) dari notifikasi. Masalahnya:

- **iOS Simulator tidak pernah menerima APNs token.** `firebase_messaging`
  memanggil `_APNSTokenCheck()` dan melempar `apns-token-not-set`, sehingga
  `getToken()`, `onTokenRefresh`, dan `subscribeToTopic()` semuanya gagal —
  begitu juga kiriman dari Firebase Console.
- Aplikasi juga harus tetap berjalan **tanpa konfigurasi Firebase sama sekali**
  (tanpa `google-services.json` / `GoogleService-Info.plist`) untuk menguji
  auth, secure storage, dan router.

## Decision
Pemilihan jalur dilakukan saat startup di `main.dart` (`_bootstrapPush`):

1. **Jalur FCM** — bila `Firebase.initializeApp()` berhasil dan izin diberikan:
   token lifecycle, topik, dan tiga app state semuanya aktif. Ini jalur
   produksi.
2. **Jalur jembatan native** — bila Firebase tidak terkonfigurasi dan platform
   iOS (termasuk Simulator): `AppDelegate.swift` mendaftar ke
   `UNUserNotificationCenter` sendiri dan meneruskan payload `simctl push`
   ke Dart lewat `EventChannel` (`NativePushBridge`). Tiga app state dan deep
   link bisa diuji, tanpa token/topik.
3. **Jalur disabled** — selain itu (mis. Android tanpa Firebase): push jarak
   jauh mati; auth, secure storage, router, dan notifikasi lokal tetap
   berfungsi.

Deteksi ada di `AppDelegate.swift`: bila `GoogleService-Info.plist` ter-bundle,
jembatan menonaktifkan diri agar tidak ada dua sumber event yang saling
menimpa. Perilaku kedua jalur dibuat identik (`listenBridge` menirukan
`listenForeground`), dan normalisasi payload jembatan diuji konsisten dengan
jalur FCM di `test/push_bridge_test.dart`.

## Alternatives Considered

### Hanya FCM; Simulator dianggap tidak didukung
- Pros: Kode paling sedikit.
- Cons: Tiga app state tidak bisa didemokan di Simulator — padahal itu
  inti codelab; butuh perangkat fisik + APNs key untuk setiap sesi.
- Rejected: Biaya pengujian terlalu tinggi untuk lingkungan belajar.

### Hanya jembatan native (tanpa Firebase)
- Pros: Tidak perlu konfigurasi Firebase sama sekali.
- Cons: Tidak ada token lifecycle, topik, dan pengiriman produksi — inti
  materi codelab hilang.
- Rejected: Jalur produksi tetap wajib FCM.

### Stub/mock di level Dart tanpa jembatan native
- Pros: Tidak menyentuh Swift.
- Cons: Tidak mengetes jalur nyata sistem notifikasi (izin, banner,
  launch dari notifikasi) — yang justru paling sering salah.
- Rejected: Banner dan terminated-launch hanya bisa dibuktikan lewat
  sistem operasi sungguhan.

## Consequences
- Demo tiga app state bisa dijalankan di Simulator mana pun lewat
  `tool/sim_push.sh` tanpa akun Firebase.
- Ada kode Swift yang harus dirawat (`AppDelegate.swift`) — hanya untuk
  iOS dan otomatis nonaktif di produksi.
- Keterbatasan Simulator tetap jujur dilaporkan: token lifecycle dan topik
  hanya bisa dibuktikan di emulator Android (Play Services) / perangkat
  fisik.
- Status jalur aktif tampil di halaman Debug (`PushSnapshot.source`) sehingga
  penguji selalu tahu jalur mana yang sedang dipakai.
