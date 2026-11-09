# ADR-001: Token disimpan di flutter_secure_storage, bukan SharedPreferences

## Status
Accepted

## Date
2026-11-09

## Context
Aplikasi menyimpan dua token: access token (berumur pendek) dan refresh token
(berumur panjang, contoh 7 hari). Keduanya adalah kredensial setara kata sandi.

`SharedPreferences` (Android) / `NSUserDefaults` (iOS) menyimpan data sebagai
file teks biasa:

- Android: XML di `/data/data/<package>/shared_prefs/` — terbaca pada perangkat
  root, lewat `adb backup`, atau perangkat dengan bootloader ter-unlock.
- iOS: plist yang hanya dilindungi sandbox aplikasi, tidak terikat ke Secure
  Enclave seperti Keychain.

Refresh token yang bocor memungkinkan penyerang menerbitkan access token baru
berulang kali tanpa mengetahui kata sandi korban, dan korban tidak mendapat
tanda bahaya apa pun — berbeda dengan pencurian kata sandi yang terdeteksi dari
perubahan kredensial.

## Decision
Semua token hanya keluar-masuk lewat `TokenStore` (`lib/data/token_store.dart`)
yang membungkus `flutter_secure_storage` — Android Keystore /
EncryptedSharedPreferences, iOS Keychain. Tidak ada penulisan token ke storage
lain di seluruh codebase.

## Alternatives Considered

### SharedPreferences
- Pros: API sederhana, tanpa plugin tambahan, sinkron.
- Cons: Tidak terenkripsi; risiko bocor pada perangkat root/backup ADB.
- Rejected: Refresh token berumur panjang membuat risikonya tidak sepadan
  dengan kemudahan API-nya.

### Menyimpan hanya di memori (tanpa persistensi)
- Pros: Tidak ada sama sekali di disk.
- Cons: Sesi hilang setiap aplikasi dimatikan — pengguna harus login ulang
  setiap membuka aplikasi.
- Rejected: Pengalaman pengguna tidak dapat diterima untuk aplikasi kampus
  yang menerima notifikasi harian.

## Consequences
- Token tidak bisa dibaca dengan mudah dari backup atau perangkat root.
- `TokenStore` adalah satu-satunya pintu: pengujian sesi (login, refresh,
  clear) dilakukan lewat interface ini sehingga bisa di-fake di unit test
  (`test/fakes.dart`).
- Operasi secure storage bersifat async — semua call site harus `await`.
- Token hanya dikirim lewat body POST HTTPS, bukan query URL yang tercatat di
  log server/proxy.
