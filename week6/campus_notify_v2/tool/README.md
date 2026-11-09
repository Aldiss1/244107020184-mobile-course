# Alat bantu pengujian

## `sim_push.sh`

Mengirim payload notifikasi ke iOS Simulator lewat `xcrun simctl push`, lalu
opsional mengambil screenshot.

```bash
./tool/sim_push.sh foreground
./tool/sim_push.sh background
./tool/sim_push.sh terminated
./tool/sim_push.sh data-only
./tool/sim_push.sh malformed

SHOT=1 ./tool/sim_push.sh foreground
```

Variabel lingkungan:

| Variabel | Default | Fungsi |
|---|---|---|
| `BUNDLE_ID` | `id.ac.polinema.campusNotify` | Target bundle |
| `DEVICE` | simulator yang sedang boot | UDID tujuan |
| `SHOT` | `0` | `1` = ambil screenshot |
| `WAIT` | `3` | Jeda sebelum screenshot (detik) |

Untuk state `terminated`, skrip memanggil `simctl terminate` lebih dulu.
Tanpa itu iOS menganggap aplikasi masih background dan `getInitialMessage`
tidak terpicu.

## `payloads/`

| File | Isi | Dipakai untuk |
|---|---|---|
| `announcement.apns` | `aps.alert` + `route` + `id` | foreground, background, terminated |
| `data_only.apns` | `content-available` tanpa `alert` | menguji perilaku data-only |
| `malformed.apns` | tanpa `route`/`id` | menguji fallback rute ke `/` |

Bentuk payload meniru FCM: `aps` untuk teks yang dibaca manusia, key
top-level lain (`route`, `id`) menjadi `data` di sisi aplikasi. Aturan ini
mengikuti `firebase_messaging`, yang membuang `aps`, `gcm.*`, dan `google.*`
dari `data`.

## Kenapa tidak pakai Firebase Console di simulator

iOS Simulator tidak pernah menerima APNs token, sehingga Firebase tidak bisa
memberi FCM token di sana (`getToken()` melempar `apns-token-not-set`).
`simctl push` menyuntikkan payload langsung ke aplikasi, dan
`ios/Runner/AppDelegate.swift` meneruskannya ke Dart lewat `EventChannel`.

Batasnya: token lifecycle dan topic messaging **tidak** bisa dibuktikan dengan
cara ini. Lihat bagian "Yang tidak bisa dibuktikan di iOS Simulator" di
`README.md`.
