# ADR-003: Satu sumber konstanta rute untuk GoRouter dan payload FCM

## Status
Accepted

## Date
2026-11-09

## Context
Notifikasi membawa deep link sebagai data (`data.route` pada payload FCM, atau
payload jembatan simulator). Rute yang sama juga dideklarasikan di GoRouter.
Bila path ditulis sebagai string literal di dua tempat yang berbeda, perubahan
di satu tempat membuat deep link "nyasar" — klik notifikasi membuka halaman
salah atau tidak sama sekali, tanpa error kompilasi apa pun.

## Decision
Seluruh path rute dideklarasikan satu kali di `lib/domain/routes.dart`
(`Routes`), berupa konstanta (`/login`, `/`, `/notifikasi`, `/debug`,
pola `/pengumuman/:id`, dst.) plus helper `Routes.announcement(id)`.

Konstanta ini dipakai oleh:

- `router_provider.dart` saat membangun `GoRoute`,
- `route_parser.dart` saat memetakan payload notifikasi ke path,
- call site navigasi mana pun (`context.go(Routes....)`).

Tidak boleh ada string path rute yang ditulis literal di luar file ini.

## Alternatives Considered

### String literal tersebar di tiap file
- Pros: Tidak perlu file tambahan.
- Cons: Refactor rute = mencari string satu per satu; deep link senyap
  rusak.
- Rejected: Bug kategori paling sulit ditemukan karena tidak gagal kompilasi.

### Nama rute saja tanpa path (`goNamed`)
- Pros: Path bebas berubah.
- Cons: Payload FCM dari backend membawa path, bukan nama — tetap butuh
  tabel konversi; nama pun tetap perlu satu sumber.
- Rejected: Menambah lapisan tanpa menghapus masalahnya. (`announcementName`
  tetap disediakan bila kelak perlu `goNamed`.)

## Consequences
- Mengubah/menambah rute cukup di satu file; GoRouter dan deep link
  otomatis konsisten.
- `routeFromMessage()` murni memetakan payload → konstanta, sehingga uji
  rute tidak butuh Firebase atau emulator.
- Konvensi ini harus dijaga saat review: PR yang menulis path literal di
  luar `routes.dart` ditolak.
