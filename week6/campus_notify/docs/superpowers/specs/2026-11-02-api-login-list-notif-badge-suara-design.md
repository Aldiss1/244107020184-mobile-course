# Desain: Login API + Daftar Notifikasi + Badge + Suara + Firebase

Tanggal: 2026-11-02 · Status: draf — menunggu persetujuan · Skala: kecil–sedang (satu sesi implementasi)

## Tujuan & alasan

Aplikasi codelab Minggu 6 (Campus Notify) saat ini memakai mock login dan
tidak punya riwayat notifikasi. Yang diminta:

1. Login memakai API sungguhan (bebas pilih) → dipilih **dummyjson.com**
   (sudah diuji langsung: `POST /auth/login` mengembalikan
   accessToken TTL 1 jam + refreshToken TTL 30 hari; kredensial salah →
   HTTP 400 "Invalid credentials"; `POST /auth/refresh` berfungsi).
2. Notifikasi tersimpan dalam daftar di dalam app; item **hilang saat
   dibaca**.
3. Badge jumlah notifikasi belum dibaca di ikon app (+ badge dalam app).
4. Bonus: notifikasi bersuara.
5. Firebase disetup agar push beneran bisa dikirim dari Firebase Console
   ke emulator (pilihan "Opsi B" dari pembuat).

Target pengujian: **emulator Android** (`sdk gphone64 arm64`, API 36,
launcher Google standar).

## Goals

- Login beneran ke dummyjson; interceptor 401→refresh yang sudah ada
  langsung berfungsi nyata (bukan simulasi).
- Daftar notifikasi persisten (tetap ada setelah app restart);
  tap item = buka pengumuman + item dihapus.
- Badge sistem (Android broadcast + iOS `setBadgeNumber`) dan badge
  dalam app (angka di ikon bel).
- Suara default sistem pada banner notifikasi Android.
- FCM aktif: token muncul di halaman Debug, push dari Firebase Console
  sampai ke emulator.

## Non-goals

- Registrasi akun baru (dummyjson tidak punya endpoint register).
- Backend penyimpanan token FCM (dummyjson tidak punya `/devices`);
  panggilan `POST /devices` tetap dipertahankan sebagai demo codelab —
  404-nya sudah di-catch dan di-log (keputusan pembuat).
- Badge ikon di launcher Google standar: **tidak akan terlihat** di
  emulator (batasan launcher, bukan bug kode — sudah diketahui pembuat).
  Bukti badge di emulator = badge dalam app (angka di ikon bel).
- Suara notifikasi foreground iOS (batasan sistem iOS; jalur iOS tidak
  jadi target run kali ini).

## Constraints

- `google-services.json` belum ada; pembuatannya butuh akun Google
  pemilik (langkah manual, lihat bagian 5).
- Interceptor Dio tidak boleh memanggil refresh lewat Dio yang sama
  (potensi loop 401); refresh memakai Dio polos terpisah.
- Handler background FCM (isolate terpisah) tidak boleh menyentuh
  provider/UI.
- `flutter analyze` → No issues; `flutter test` → semua lulus (17 tes
  lama disesuaikan).

## Approaches (pertimbangan)

| # | Pilihan | Nasib |
|---|---|---|
| 1 | **API dummyjson.com** | ✅ **dipilih** — gratis tanpa akun, token access+refresh asli cocok dengan arsitektur app, 401→refresh benar-benar bisa diuji |
| 2 | Firebase Auth | Ditolak — butuh setup terpisah dan mengubah arsitektur token; pembuat memilih "API bebas" |
| 3 | Backend mock lokal | Ditolak — harus menjalankan server terpisah, merepotkan untuk demo |

Penyimpanan daftar notifikasi: **file JSON** di direktori dokumen app
(`path_provider`). Ditimbang: `shared_preferences` (cukup, tapi kurang
rapi untuk struktur list) dan `sqflite` (overkill untuk daftar pendek).
Keputusan pembuat: file JSON dengan dependency injection `File` agar
unit test memakai direktori temp.

Badge Android: **MethodChannel + broadcast** (teknik standar
`APPWIDGET_UPDATE` + action badge berisi extra count) — berfungsi di
launcher bermerek (Samsung/Xiaomi/Oppo/Vivo), tidak terlihat di launcher
Google standar. Alternatif plugin pihak ketiga ditolak: dependensi
besar untuk fitur yang tidak terlihat di target pengujian.

## Keputusan per fitur

### 1. Login dummyjson

- `baseUrl` Dio → `https://dummyjson.com`.
- `AuthRepository` diubah:
  - `login(username, password)` → `POST /auth/login`
    `{username, password}` → `AuthSession(access, refresh)`.
    HTTP 400 → `AuthException('Username atau kata sandi salah.')`
  - `refresh(refreshToken)` → `POST /auth/refresh` `{refreshToken}`
    → **`AuthSession` baru** (access + refresh; keduanya disimpan di
    secure storage).
  - `profile(accessToken)` → `GET /users/me` (header Bearer) →
    `UserProfile {firstName, lastName, email, image}`.
  - Constructor menerima `Dio?` (default: Dio polos, baseUrl +
    timeout 10 dtk) — **tidak memakai** Dio ber-interceptor.
- Interceptor `api_client.dart`: simpan access **dan** refresh baru.
- Form login: label "Username" (default `emilys`), "Kata sandi"
  (default `emilyspass`); validator cukup non-empty.
- Halaman Home: tampilkan nama user dari `userProfileProvider`
  (diambil saat startup bila ada sesi; gagal → sapaan netral).

### 2. Daftar notifikasi

- Model `StoredNotification {id, title, body, route, createdAt}`.
- `NotificationStore` (file JSON, DI `File`): `load/add/remove/clear`,
  state reaktif `ValueNotifier<List<...>>`.
- Riverpod: `notificationsProvider` (Notifier) — sumber reaktif untuk
  badge dan halaman daftar.
- Sumber pengisian satu titik: callback `PushService.onIncoming`
  (dipasang di bootstrap `main.dart`) dipanggil setiap notifikasi
  ditampilkan — mencakup tombol "Tampilkan notifikasi lokal", FCM
  foreground, bridge iOS, dan saat app dibuka dari notifikasi
  (`onMessageOpenedApp` / initial message).
- UI:
  - Ikon bel di AppBar Home + `Badge` (jumlah = panjang daftar;
    disembunyikan saat 0).
  - Halaman baru `/notifikasi` (`Routes.notifications`): item berisi
    judul, cuplikan isi, waktu singkat; tap → `router.go(item.route)`
    lalu item dihapus (dibaca = hilang).
  - State kosong: "Belum ada notifikasi."
  - Menu "Hapus semua" (keputusan pembuat, fitur kecil).

### 3. Badge

- Dalam app: `Badge` Material 3 di ikon bel (selalu terlihat,
  termasuk di emulator).
- Sistem: MethodChannel `campus_notify/badge` di `MainActivity.kt`
  (broadcast `APPWIDGET_UPDATE` + action badge dengan extra count) +
  iOS `setBadgeNumber` via `flutter_local_notifications`.
- Dipanggil setiap daftar berubah (tambah/hapus/hapus semua) dan saat
  logout (reset ke 0).
- Catatan demo: di emulator standar tidak terlihat di layar utama —
  sudah dibenarkan pembuat.

### 4. Suara

- Android: channel `pengumuman` (`Importance.high`) memutar suara
  default; dibuat eksplisit di `NotificationDetails`.
- iOS: `DarwinNotificationDetails(playSound: true)` eksplisit (jalur
  sekunder, tidak diuji kali ini).

### 5. Firebase (Opsi B)

**Langkah pembuat (butuh akun Google):**
1. https://console.firebase.google.com → **Add project** (nama bebas;
   Analytics boleh dilewati).
2. Halaman project → **Add app** → ikon **Android** → isi package name
   persis: `id.ac.polinema.campus_notify` → **Register app**.
3. Unduh `google-services.json` → simpan ke
   `android/app/google-services.json`.
4. Beri tahu saya (atau cukup letakkan filenya — saya lanjutkan).

**Langkah saya:**
- `android/app/build.gradle.kts` sudah otomatis mengaktifkan plugin
  google-services saat file ada (baris 10–12) — tidak perlu diubah.
- Restart penuh `flutter run` → token FCM muncul di halaman Debug.
- Uji push: Firebase Console → Messaging → Create campaign →
  Notification → Custom data `{"route": "/pengumuman/3", "id": "3"}`.
- Catatan: image emulator `sdk gphone64` (Google APIs) sudah memuat
  Google Play Services sehingga FCM bisa jalan; bila token tetap null,
  ganti AVD ke image dengan Google Play.
- `POST /devices` akan 404 di dummyjson — dipertahankan (syarat
  codelab: token benar-benar dikirim), error sudah di-catch.

## Rencana tes

- Kelompok "sesi & refresh" ditulis ulang memakai Dio mock adapter
  (respons JSON bawaan): login sukses → sepasang token; login 400 →
  `AuthException`; refresh → pasangan token baru.
- Tes baru `NotificationStore` (direktori temp): add → persist,
  remove, clear, load ulang dari file.
- Tes `friendlyError`, `routeFromMessage`, `BridgePushPayload` tetap.
- Gerbang: `flutter analyze` → No issues; `flutter test` → semua lulus.

## Ditinggalkan untuk pembuat (builder)

- Detail micro-layout halaman daftar.
- Format waktu relatif ("baru saja", "x menit lalu").
- Teks snackbar kecil bila diperlukan.

## Dokumen yang ikut diperbarui

- `README.md`: bagian "Login demo" (API nyata + kredensial dummy),
  bagian baru daftar/badge/suara, instruksi setup Firebase, struktur
  folder.
