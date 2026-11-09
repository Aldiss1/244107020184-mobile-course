# Campus Notify — Minggu 6: Authentication, Security & FCM

Aplikasi Flutter contoh untuk codelab **#06 Authentication, Security & FCM**
(JTI Polinema). Fokusnya bukan pada tampilan, tetapi pada empat hal yang
sering salah di aplikasi mobile:

1. **Token disimpan aman** — `flutter_secure_storage` (Keystore/Keychain),
   bukan `SharedPreferences`.
2. **Access token diperbarui otomatis** — interceptor Dio me-refresh sekali
   saat 401, lalu mengulang request sekali. Kalau refresh ikut mati, sesi
   dihapus dan pengguna dipaksa login ulang.
3. **Deep link dari notifikasi konsisten** — satu sumber konstanta rute
   (`lib/routes.dart`) dipakai GoRouter *dan* pemetaan payload FCM.
4. **Tiga app state teruji** — foreground, background, terminated.

---

## Stack

| Kebutuhan | Package |
|---|---|
| State management | `flutter_riverpod` 3 |
| Routing + guard | `go_router` 18 |
| HTTP + interceptor | `dio` 5 |
| Penyimpanan token | `flutter_secure_storage` 11 |
| Push notification | `firebase_core`, `firebase_messaging` 17 |
| Banner foreground | `flutter_local_notifications` 22 |

---

## Struktur folder

```
lib/
├── main.dart                     # boot Firebase (guard) + pilih jalur push
├── domain/
│   ├── routes.dart               # SATU sumber path rute
│   └── route_parser.dart         # routeFromMessage() — fungsi murni
├── data/
│   ├── token_store.dart          # secure storage saja
│   ├── auth_repository.dart      # auth dummyjson, titik migrasi ke API kampus
│   ├── api_client.dart           # Dio + refresh-once interceptor
│   ├── api_errors.dart           # DioException -> pesan ramah pengguna
│   ├── push_service.dart         # permission, token, topic, 3 handler
│   ├── native_push_bridge.dart   # jembatan push iOS Simulator
│   └── notification_store.dart   # daftar notifikasi in-app (file JSON)
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart    # AsyncNotifier<bool> status login
│   │   ├── router_provider.dart  # GoRouter + redirect guard
│   │   ├── push_provider.dart    # provider PushService + status boot Firebase
│   │   └── notification_provider.dart
│   └── pages/
│       ├── splash_page.dart
│       ├── login_page.dart
│       ├── home_page.dart
│       ├── notifications_page.dart
│       ├── announcement_page.dart # target deep link /pengumuman/:id
│       ├── debug_page.dart        # bukti token terpotong + status push
│       └── ...                   # slide materi SOLID & Layer-first
```

ios/Runner/AppDelegate.swift      # bridge EventChannel/MethodChannel (simulator)
tool/
├── sim_push.sh                   # kirim payload + screenshot
└── payloads/
    ├── announcement.apns         # notification + data (3 state)
    ├── data_only.apns            # data-only, tanpa aps.alert
    └── malformed.apns            # tanpa route, uji fallback ke '/'
```

---

## Dua jalur push yang didukung

Aplikasi punya dua sumber event push, dipilih otomatis saat startup:

| Kondisi | Sumber | Yang bisa diuji |
|---|---|---|
| `google-services.json` / `GoogleService-Info.plist` ada | **Firebase Cloud Messaging** | Semua: token lifecycle, topic, 3 app state |
| Firebase tidak ada, tapi iOS (termasuk Simulator) | **Jembatan native** (`AppDelegate.swift`) | 3 app state + deep link, **tanpa** token/topic |
| Selain itu (Android tanpa Firebase) | Tidak ada push | Auth, secure storage, router, notifikasi lokal |

Deteksinya di `AppDelegate.swift`: bila `GoogleService-Info.plist` tidak
ter-bundle, aplikasi mendaftar ke `UNUserNotificationCenter` sendiri dan
meneruskan payload `simctl push` ke Dart lewat `EventChannel`. Bila plist ada,
bridge menonaktifkan diri agar tidak ada dua sumber event yang saling menimpa.


---

## Cara menjalankan

```bash
flutter pub get
flutter analyze          # harus: No issues found!
flutter test             # harus: All tests passed!
flutter run
```

### Login demo

Mock auth menerima email apa pun yang mengandung `@` dan kata sandi minimal
6 karakter. Nilai default pada form sudah memenuhi syarat.

### Mengaktifkan FCM (opsional untuk auth, wajib untuk push)

Aplikasi **tetap bisa dijalankan tanpa konfigurasi Firebase**: halaman login,
secure storage, guard rute, dan notifikasi lokal semuanya berfungsi. Status
push akan tampil "Firebase belum dikonfigurasi" di halaman Debug.

Untuk mengaktifkan FCM:

1. Buat project di [Firebase Console](https://console.firebase.google.com)
   (paket Spark, tanpa kartu kredit).
2. Tambahkan aplikasi **Android** dengan package name
   `id.ac.polinema.campus_notify`.
3. Unduh `google-services.json` → taruh di `android/app/`.
   Plugin `com.google.gms.google-services` akan otomatis aktif karena
   `android/app/build.gradle.kts` mengecek keberadaan file tersebut.
4. (iOS) Tambahkan aplikasi iOS dengan bundle ID
   `id.ac.polinema.campusNotify` (perhatikan: iOS memakai camelCase karena
   underscore tidak lazim untuk bundle ID Apple, sedangkan Android memakai
   `applicationId` dengan underscore). Unduh `GoogleService-Info.plist` →
   drag ke `ios/Runner/` lewat Xcode, lalu aktifkan capability **Push
   Notifications** dan **Background Modes → Remote notifications**, serta
   unggah **APNs Auth Key** di Firebase Console.
5. `flutter run` ulang (bukan hot reload — plugin baru butuh restart penuh).

Endpoint pelaporan token ada di `main.dart` (`dio.post('/devices', ...)`).
Ganti `baseUrl` di `lib/data/api_client.dart` dengan API kampus Anda.

### Menguji tanpa backend

Firebase Console → **Messaging** → *Create campaign* → **Notification**.
Kirim dengan **Additional options → Custom data**:

```json
{ "route": "/pengumuman/3", "id": "3" }
```

### Menguji di iOS Simulator (`simctl push`)

iOS Simulator tidak pernah menerima APNs token, sehingga Firebase tidak bisa
memberi FCM token di sana. Untuk tetap bisa menguji tiga app state, aplikasi
memakai jembatan native yang menerima payload `simctl push`.

```bash
open -a Simulator
flutter run -d <udid-simulator>

# terminal lain
./tool/sim_push.sh foreground      # aplikasi terbuka
./tool/sim_push.sh background      # setelah menekan Home
./tool/sim_push.sh terminated      # skrip mematikan app lebih dulu
./tool/sim_push.sh data-only       # uji perilaku data-only
./tool/sim_push.sh malformed       # uji fallback rute ke '/'

# kirim + screenshot otomatis
SHOT=1 ./tool/sim_push.sh foreground
```

Payload yang dikirim berbentuk APNs dengan tambahan `data` FCM:

```json
{
  "Simulator Target Bundle": "id.ac.polinema.campusNotify",
  "aps": { "alert": { "title": "Jadwal kuliah berubah",
                      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00" },
           "sound": "default" },
  "gcm.message_id": "sim-announcement-0001",
  "route": "/pengumuman/3",
  "id": "3"
}
```

---

## Tabel pengujian tiga app state

Diuji di **iPhone 14 Pro Max simulator, iOS 26.5**, memakai
`tool/sim_push.sh` (jalur jembatan native). Kolom hasil diisi berdasarkan
pengujian nyata.

| State | Yang diharapkan | Cara uji | Hasil |
|---|---|---|---|
| **Foreground** | Banner lokal muncul (sistem tidak menampilkannya otomatis), klik masuk ke `/pengumuman/3` | Aplikasi terbuka, `./tool/sim_push.sh foreground`, klik banner | ⬜ belum diuji |
| **Background** | Banner sistem muncul, klik membuka `/pengumuman/3` lewat handler `opened` | Tekan Home, `./tool/sim_push.sh background`, klik banner | ⬜ belum diuji |
| **Terminated** | Aplikasi terbuka langsung ke `/pengumuman/3` lewat `getInitialPayload()` | `./tool/sim_push.sh terminated`, klik banner | ⬜ belum diuji |
| **Data-only** | Tidak ada banner otomatis; payload hanya diteruskan ke handler | `./tool/sim_push.sh data-only` | ⬜ belum diuji |
| **Tanpa route** | Fallback ke `/` (Home), bukan crash | `./tool/sim_push.sh malformed` | ⬜ belum diuji |

### Token lifecycle

| Langkah | Yang diharapkan | Hasil |
|---|---|---|
| Buka halaman Debug | Token tampil **terpotong** (12 karakter + `...`) | ⬜ belum diuji — butuh Android/perangkat fisik |
| Hapus data aplikasi / reinstall | `onTokenRefresh` mengirim token baru ke backend, preview di Debug berubah | ⬜ belum diuji — butuh Android/perangkat fisik |
| Screenshot laporan | Tidak ada token penuh yang terlihat | ⬜ belum diuji |

### Yang **tidak** bisa dibuktikan di iOS Simulator

Harus dinyatakan jujur di laporan, bukan diklaim lulus:

| Item | Alasan teknis |
|---|---|
| `getToken()` | `firebase_messaging` memanggil `_APNSTokenCheck()` dan melempar `apns-token-not-set`; APNs token tidak diterbitkan untuk Simulator |
| `onTokenRefresh` | Tidak pernah emit karena token tidak pernah terbit |
| `subscribeToTopic()` / `unsubscribeFromTopic()` | Juga melewati `_APNSTokenCheck()`, jadi melempar error yang sama |
| Kiriman dari Firebase Console | Console mengirim via FCM → APNs → perangkat; Simulator tidak punya APNs token |
| Perbedaan perilaku terminated iOS asli | Di perangkat fisik, swipe-close membuat iOS **tidak** mengirim pesan data-only; di simulator `simctl push` selalu menyuntikkan payload |

Untuk melengkapi bagian ini, jalankan aplikasi di **emulator Android dengan
Google Play Services** (gratis) atau perangkat fisik.

Bukti gambar disimpan di `screenshots/`:

- `screenshots/token-truncated.png`
- `screenshots/foreground.png`
- `screenshots/background.png`
- `screenshots/terminated.png`
- `screenshots/fcm-console-test.png`

---

## Keputusan desain yang perlu bisa dijelaskan saat demo

Setiap keputusan signifikan didokumentasikan lengkap sebagai Architecture
Decision Record di [`docs/decisions/`](docs/decisions/) — konteks, alternatif
yang ditolak, dan konsekuensinya. Ringkasannya:

| Pertanyaan | Jawaban singkat di kode | ADR |
|---|---|---|
| Kenapa bukan `SharedPreferences`? | Tidak terenkripsi. Di Android file XML-nya bisa dibaca pada perangkat root/backup; di iOS plist tidak dilindungi Keychain. Lihat `token_store.dart`. | [ADR-001](docs/decisions/ADR-001-secure-storage-untuk-token.md) |
| Kenapa refresh hanya sekali? | Mencegah loop tak berujung saat backend terus membalas 401. Ditandai lewat `extra['retried_after_refresh']` di `api_client.dart`. | [ADR-002](docs/decisions/ADR-002-refresh-once-interceptor.md) |
| Kenapa background handler top-level? | Berjalan di isolate terpisah yang dibuat native; tidak ada `BuildContext`/`ProviderContainer`. Lihat `@pragma('vm:entry-point')` di `push_service.dart`. | — |
| Kenapa foreground butuh local notification? | Pada state foreground, sistem **tidak** menampilkan banner untuk payload `notification`. Harus manual. | — |
| Topik vs token? | Topik untuk broadcast (semua mahasiswa, satu kelas, satu UKM). Token untuk pesan personal (nilai, tagihan). | — |
| Kenapa `routeFromMessage` dipisah? | Supaya logika pemetaan payload bisa diuji tanpa Firebase. Lihat `test/auth_push_test.dart`. | [ADR-006](docs/decisions/ADR-006-route-parser-murni.md) |
| Kenapa rute pusat di `routes.dart`? | GoRouter dan payload FCM memakai konstanta yang sama; deep link tidak bisa "nyasar". | [ADR-003](docs/decisions/ADR-003-single-source-rute.md) |
| Kenapa ada dua jalur push? | iOS Simulator tidak punya APNs token; jembatan native membuat 3 app state tetap bisa diuji. | [ADR-004](docs/decisions/ADR-004-dua-jalur-push.md) |
| Kenapa berlapis `data/domain/presentation`? | Dependensi satu arah, logika murni teruji tanpa perangkat — contoh hidup materi Minggu 7. | [ADR-005](docs/decisions/ADR-005-arsitektur-berlapis-riverpod.md) |

Laporan proyek lengkap (format Word): `docs/Laporan_Campus_Notify_v2.docx`.

---

## Hasil verifikasi

```
$ flutter analyze
No issues found!

$ flutter test
00:00 +17: All tests passed!

$ flutter build ios --debug --no-codesign
✓ Built build/ios/iphoneos/Runner.app

$ flutter build ios --simulator --debug
✓ Built build/ios/iphonesimulator/Runner.app

$ flutter build apk --debug
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

`flutter doctor` — semua hijau (Flutter 3.47.2, Android SDK 36.0.0, Xcode 26.6).

### Catatan setup Android di mesin ini

Dua masalah lingkungan yang sudah diperbaiki dan perlu diketahui bila
proyek ini dibangun ulang di mesin lain:

1. **`cmdline-tools` tidak terpasang.** Tanpa `sdkmanager`, Flutter tidak bisa
   menyediakan NDK sendiri (`forceNdkDownload` di `FlutterPlugin.kt`) sehingga
   Gradle berhenti di `CXX1101` / `NDK not configured`. Perbaikannya memasang
   `cmdline-tools` ke `$ANDROID_HOME/cmdline-tools/latest` lalu
   `sdkmanager --licenses`.
2. **Stub NDK rusak.** Folder `ndk/28.2.13676358` hanya berisi `.installer`
   (unduhan gagal separuh). Dihapus. Pin `ndkVersion` di
   `android/app/build.gradle.kts` juga dilepas karena proyek ini tidak punya
   kode native.

Waktu build pertama ±12 menit karena Gradle harus mengunduh platform SDK 36
dan CMake 3.22.1. Build berikutnya jauh lebih cepat.

Test yang tersedia (34):

- `routeFromMessage` — rute kosong, tanpa garis miring, fallback ke `id`, trim spasi
- sesi — login menyimpan token, kredensial invalid ditolak, refresh menghasilkan token baru, refresh kosong memaksa login ulang
- `friendlyError` — 401, connection error, dan `AuthException`
- `BridgePushPayload.fromMap` — normalisasi payload jembatan iOS, field
  hilang, koersi tipe, dan konsistensi rute dengan jalur FCM

---

## Error umum dan solusinya

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| Token `null` di emulator | Emulator tanpa Google Play Services | Pakai AVD dengan ikon Play Store, atau perangkat fisik |
| `apns-token-not-set` di iOS | Dijalankan di Simulator, atau APNs key belum diunggah | Simulator: pakai `tool/sim_push.sh`. Perangkat: unggah APNs Auth Key + aktifkan capability Push |
| Banner tidak muncul saat foreground | Mengandalkan banner otomatis sistem | Tampilkan manual via `flutter_local_notifications` di `onMessage` — sudah diterapkan |
| Banner **muncul dua kali** di iOS | Firebase default `alert: true` + local notification | `setForegroundNotificationPresentationOptions(alert: false, ...)` — sudah diterapkan |
| Klik notifikasi tidak navigasi (terminated) | `getInitialMessage()` dipanggil sebelum router siap | Panggil di `addPostFrameCallback` setelah `routerProvider` terbentuk — sudah diterapkan |
| 401 berulang meski sudah login | Interceptor mengulang request tanpa batas, atau refresh ikut kedaluwarsa | Tandai retry sekali via `extra['retried_after_refresh']`; bila refresh gagal, `clear()` lalu ke `/login` |
| `MissingPluginException` secure storage / messaging | Hot reload setelah menambah plugin | Hentikan penuh lalu `flutter run` ulang |
| Notifikasi iOS tidak muncul | Belum ada APNs key / capability push | Konfigurasi APNs di Firebase Console + aktifkan Push di Xcode |
| `getToken` deprecated | `firebase_messaging` 17 memakai `register()`/`onRegistered` | Sementara di-`ignore` sesuai tuntutan codelab; lihat `docs/ai-challenge.md` |
| Gradle gagal: `google-services.json` tidak ditemukan | Plugin dipasang tanpa file konfigurasi | Sudah dicegah: plugin hanya di-`apply` bila file ada (`android/app/build.gradle.kts`) |
| Build Android gagal: `core library desugaring` | `flutter_local_notifications` memakai `java.time` | `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs` — sudah diterapkan |

---

## Refleksi

**1. Mengapa refresh token tidak boleh disimpan di `SharedPreferences`? Apa
risikonya bila bocor?**

`SharedPreferences` menyimpan data sebagai XML biasa di direktori privat app
(`/data/data/<package>/shared_prefs/`). Direktori itu memang tidak bisa dibaca
app lain pada perangkat normal, tetapi isinya terbaca pada perangkat root,
lewat backup ADB (`adb backup`), atau pada perangkat yang di-unlock
bootloader-nya. Di iOS, `NSUserDefaults` tersimpan sebagai plist yang hanya
dilindungi sandbox aplikasi — tidak terikat ke Secure Enclave seperti Keychain.

Risikonya berat karena **refresh token berumur panjang** (di contoh ini 7
hari). Kalau bocor, penyerang bisa menukarnya menjadi access token baru
berulang kali tanpa pernah tahu kata sandi korban, dan korban tidak akan
mendapat notifikasi apa pun — berbeda dengan pencurian kata sandi yang bisa
dideteksi dari perubahan kredensial. Karena itu refresh token hanya boleh
berada di `flutter_secure_storage` (Android Keystore / iOS Keychain), dan
dikirim hanya lewat body POST HTTPS, bukan query URL yang tercatat di log
server dan proxy.

**2. Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester
perkuliahan?**

Registration token FCM berotasi, dan token lama menjadi tidak valid. Pemicunya
antara lain: reinstall aplikasi, clear data, restore dari backup, update
aplikasi dengan signing key berbeda, atau rotasi keamanan dari sisi FCM
sendiri. Tanpa listener `onTokenRefresh`, backend tetap memegang token lama
sehingga:

- pengumuman penting tidak sampai ke mahasiswa tersebut, tanpa error apa pun
  di sisi server — pengiriman tetap "sukses" ke token yang sudah mati,
- ketahuan hanya saat ada informasi mendesak yang seharusnya diterima,
- pemulihannya sulit karena tidak ada jejak kapan token terakhir valid.

Itulah sebabnya `initToken()` mewajibkan callback `onToken` yang benar-benar
mengirim token ke `POST /devices`, bukan sekadar `debugPrint`.

**3. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan
kampus untuk masing-masing.**

Topik dipakai untuk **broadcast** ke banyak pengguna dengan isi yang sama:
`pengumuman-kampus` untuk pengumuman umum, `kelas-3A` untuk jadwal satu kelas,
`ukm-robotika` untuk agenda UKM. Keuntungannya, backend tidak perlu menyimpan
ribuan token dan pengiriman cukup satu request.

Token perangkat dipakai untuk **pesan personal** yang tidak boleh diterima
orang lain: nilai akhir semester, tagihan UKT, status beasiswa, atau
peringatan login dari perangkat baru. Mengirim data seperti ini ke topik sama
dengan menyiarkannya ke seluruh angkatan.

**4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?**

Ringkasnya (detail di `docs/ai-challenge.md`):

- **Ditolak:** menyimpan token di `SharedPreferences`, menampilkan token penuh
  di halaman Debug, `debugPrint(token)` di `onTokenRefresh`, dan background
  handler berupa method kelas.
- **Diperbaiki:** signature `flutter_local_notifications` 22 yang berubah jadi
  *named parameters*; izin `POST_NOTIFICATIONS` Android 13+ yang tidak
  ditangani Firebase; channel notifikasi Android yang tidak pernah dibuat;
  interceptor yang bisa loop tanpa penanda retry; `getInitialMessage()` yang
  dipanggil sebelum router siap; dan klik notifikasi lokal foreground yang
  disimpan tetapi tidak pernah dibaca.

---

## Catatan versi

`firebase_messaging` 17 menandai `getToken()` dan `onTokenRefresh` sebagai
*deprecated* dan memperkenalkan `register()` / `onRegistered` (yang
mengembalikan Firebase Installation ID). Codelab minggu 6 masih mensyaratkan
`getToken` + `onTokenRefresh`, jadi keduanya dipakai dengan `ignore` eksplisit
dan alasannya dicatat di `docs/ai-challenge.md`.

`flutter_local_notifications` 22 mengubah API `initialize()` dan `show()`
menjadi *named parameters* — contoh kode pada banyak tutorial lama (termasuk
yang beredar di internet) masih memakai positional argument dan akan gagal
kompilasi.
