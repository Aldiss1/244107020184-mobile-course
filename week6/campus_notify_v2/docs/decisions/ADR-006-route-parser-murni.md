# ADR-006: routeFromMessage() sebagai fungsi murni yang terpisah

## Status
Accepted

## Date
2026-11-09

## Context
Klik notifikasi harus menavigasi ke rute yang ditentukan payload. Logika
pemetaannya punya banyak kasus tepi: `route` kosong/absen, fallback ke `id`,
path tanpa garis miring awal, spasi di ujung string. Bila logika ini hidup di
dalam callback FCM (`onMessageOpenedApp` dsb.), mengujinya membutuhkan
Firebase, izin, perangkat — praktis tidak pernah diuji.

## Decision
Pemetaan payload → path diekstrak menjadi fungsi **murni** top-level
`routeFromMessage(Map<String, dynamic>)` di `lib/domain/route_parser.dart`:

- tidak menyentuh Firebase, `BuildContext`, provider, atau I/O;
- aturannya lengkap dan terdokumentasi: `route` kosong → fallback `id` →
  fallback `Routes.home`; tanpa `/` di depan ditambahkan; spasi di-trim;
- semua call site push (FCM foreground/background/terminated dan jembatan
  native) memanggil fungsi yang sama.

Karena murni, kasus-kasus tepinya diuji di `test/auth_push_test.dart` dengan
`flutter test` biasa — tanpa perangkat, tanpa Firebase.

## Alternatives Considered

### Logika inline di tiap handler FCM
- Pros: Tidak perlu file baru.
- Cons: Terduplikasi di ≥4 handler (foreground, opened, terminated, bridge);
  kasus tepi hanya bisa diuji di perangkat.
- Rejected: Duplikasi + tidak testable adalah kombinasi terburuk untuk
  kode yang paling sering salah.

### Parser sebagai method di PushService
- Pros: Terkumpul di satu kelas.
- Cons: Mengujinya tetap butuh menginstansiasi `PushService` (plugin
  notifikasi lokal); method kelas menyeret konteks instance.
- Rejected: Fungsi top-level murni lebih murah diuji.

### Validasi rute di sisi backend (payload selalu benar)
- Pros: Client paling sederhana.
- Cons: Client tetap harus menangani payload lama/salah (lihat uji
  `malformed.apns`) — server tidak bisa menjamin semua pengirim disiplin.
- Rejected: Client wajib defensif terhadap payload.

## Consequences
- Kasus tepi deep link punya suite regresi: setiap perbaikan parser
  dikunci lewat test, buang-buang debug di emulator tidak diperlukan.
- Fungsi ini juga jadi contoh materi kuliah: logika kecil yang diuji
  langsung karena diletakkan di `domain/`.
- Perubahan aturan pemetaan cukup di satu tempat; kedua jalur push
  (FCM & bridge) otomatis mengikuti.
