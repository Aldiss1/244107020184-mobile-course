# ADR-002: Refresh-once interceptor pada Dio

## Status
Accepted

## Date
2026-11-09

## Context
Access token kedaluwarsa lebih cepat daripada sesi pengguna. Tanpa mekanisme
perpanjangan otomatis, pengguna dipaksa login ulang setiap kali access token
habis. Mekanisme umumnya interceptor HTTP: saat request mendapat 401, tukar
refresh token menjadi access token baru, lalu ulangi request.

Bahaya implementasi naif: **loop tak berujung**. Bila backend terus membalas
401 (token baru pun ditolak, atau endpoint memang butuh role lain), interceptor
yang mengulang tanpa batas akan membanjiri backend dan menghabiskan baterai.

## Decision
Interceptor di `buildApiClient()` (`lib/data/api_client.dart`) melakukan
refresh **maksimal satu kali** per request:

1. `onRequest` menyematkan header `Authorization` dari secure storage.
2. `onError` hanya bereaksi pada 401 **dan** request yang belum pernah di-retry
   — ditandai lewat `options.extra['retried_after_refresh'] = true`.
3. Refresh token ditukar lewat `auth.refresh()`; karena backend (dummyjson)
   **merotasi pasangan token**, access dan refresh yang baru keduanya disimpan
   ulang ke secure storage.
4. Request diulang sekali lewat `dio.fetch(options)` lalu hasilnya di-resolve.
5. Bila refresh sendiri gagal/kedaluwarsa → `store.clear()` dan error
   diteruskan, sehingga lapisan auth memaksa login ulang.

## Alternatives Considered

### Retry tanpa penanda (loop selama 401)
- Pros: Kode lebih pendek.
- Cons: Loop tak berujung saat backend terus menolak.
- Rejected: Penanda satu-retry adalah pencegah bug paling murah.

### Refresh proaktif berbasis jam (refresh sebelum expire)
- Pros: Tidak ada latensi ekstra satu round-trip.
- Cons: Perlu membaca claim `exp` dari JWT dan menyinkronkan jam client-server.
- Rejected untuk codelab: kompleksitas tidak sepadan; refresh-once sudah
  menutup kebutuhan sesi 7 hari.

### Melempar 401 ke UI dan meminta user login ulang
- Pros: Paling sederhana.
- Cons: Pengguna login ulang berkali-kali sehari.
- Rejected: Pengalaman pengguna buruk untuk notifikasi kampus.

## Consequences
- Request yang tetap 401 setelah retry diteruskan sebagai error biasa — tidak
  pernah loop.
- Rotasi refresh token ditangani: pasangan baru disimpan setiap refresh.
- Refresh token yang mati selalu berujung sesi bersih (`clear()`) → rute
  guard mengarahkan ke `/login`.
- Perilaku ini teruji di `test/auth_push_test.dart` (refresh menghasilkan
  token baru, refresh kosong memaksa login ulang).
