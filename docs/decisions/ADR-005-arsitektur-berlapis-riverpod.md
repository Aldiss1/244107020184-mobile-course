# ADR-005: Arsitektur berlapis data/domain/presentation dengan Riverpod

## Status
Accepted

## Date
2026-11-09

## Context
Proyek ini berkembang dari codelab Minggu 6 (auth + FCM) menjadi contoh hidup
untuk materi Minggu 7 (SOLID & Clean Architecture — lihat halaman
`/materi/solid` dan `/materi/layer-first` di dalam aplikasi). Kode harus mudah
dijelaskan di kelas: dependensi mengalir satu arah, logika bisnis tidak
menyentuh UI, dan state bisa diuji tanpa perangkat.

## Decision
Kode diorganisasi berlapis di bawah `lib/`:

```
lib/
├── main.dart                  # bootstrap (Firebase guard, push wiring)
├── data/                      # sumber data & implementasi teknis
│   ├── token_store.dart       # secure storage
│   ├── auth_repository.dart   # login/refresh (dummyjson)
│   ├── api_client.dart        # Dio + interceptor
│   ├── push_service.dart      # FCM + local notification + bridge
│   ├── notification_store.dart# persistensi daftar notifikasi (file JSON)
│   └── ...
├── domain/                    # logika murni, tanpa framework
│   ├── routes.dart            # konstanta rute (ADR-003)
│   └── route_parser.dart      # payload -> rute (ADR-006)
└── presentation/
    ├── providers/             # Riverpod: auth, router, push, notifikasi
    └── pages/                 # widget Flutter
```

Aturan dependensi: `presentation → domain` dan `presentation → data` (lewat
provider); `domain` tidak mengimpor `data` maupun `presentation`. State
management memakai `flutter_riverpod` 3 (`AsyncNotifier` untuk status login,
provider biasa untuk router/push/notifikasi), injeksi dependensi lewat
constructor + `ProviderScope.overrides` di test.

## Alternatives Considered

### Struktur flat per-fitur (feature-first)
- Pros: File satu fitur berkumpul, enak untuk project kecil.
- Cons: Batas lapisan tidak terlihat — materi kuliah justru tentang batas
  lapisan; UI mudah memanggil repository secara langsung.
- Rejected: Tujuan pembelajaran menuntut lapisan eksplisit.

### Bloc / Provider murni (tanpa Riverpod)
- Pros: Ekosistem besar.
- Cons: Boilerplate lebih banyak (Bloc) atau injeksi manual (Provider);
  `AsyncNotifier` Riverpod sudah meng-cover status async (loading/data/error)
  dengan kode paling sedikit.
- Rejected: Kode lebih panjang tanpa keuntungan untuk skala codelab.

### Clean Architecture penuh (entities/usecases/interface per lapisan)
- Pros: Pemisahan maksimal.
- Cons: 5 file untuk satu fitur kecil — rasio infrastruktur vs isi terlalu
  besar untuk ukuran proyek.
- Rejected: Overkill; prinsip dependency rule sudah tercapai dengan 3 lapisan.

## Consequences
- Mahasiswa bisa menunjuk satu file dan menjawab "ini lapisan apa, boleh
  mengimpor apa".
- `domain/` bebas framework → pengujian rute dan parser tidak butuh emulator.
- Provider memungkinkan `PushService` dan repository di-fake di unit test
  (`test/fakes.dart`) tanpa menyentuh Firebase.
- Konsekuensi riil: penambahan fitur menyentuh beberapa folder sekaligus —
  diterima demi eksplisititas lapisan.
