# Implementation Plan: Login API + Daftar Notifikasi + Badge + Suara + Firebase

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ganti mock login dengan API dummyjson.com, tambah daftar notifikasi persisten (hilang saat dibaca), badge unread (sistem + dalam app), suara notifikasi, dan setup Firebase agar push beneran bisa diuji di emulator Android.

**Architecture:** `AuthRepository` memanggil endpoint dummyjson via Dio polos (login/refresh); Dio ber-interceptor (yang sudah ada) tetap memakai `AuthRepository.refresh` untuk alur 401→refresh. Notifikasi disimpan `NotificationStore` (file JSON) di belakang Notifier Riverpod; `PushService` memanggil callback `onIncoming` satu-satunya setiap notifikasi tampil/dibuka. Badge sistem lewat MethodChannel Android (broadcast) + `setBadgeNumber` iOS.

**Tech Stack:** Flutter 3 (Dart 3), flutter_riverpod 3, go_router 18, dio 5, flutter_secure_storage, firebase_messaging 17, flutter_local_notifications 22, path_provider (baru).

**Spec:** `docs/superpowers/specs/2026-11-02-api-login-list-notif-badge-suara-design.md`

## Global Constraints

- Package Android **`id.ac.polinema.campus_notify`** — nama ini WAJIB persis saat mendaftarkan app di Firebase Console.
- Base URL API: **`https://dummyjson.com`**; kredensial demo: username **`emilys`**, password **`emilyspass`**.
- Token hanya di `flutter_secure_storage` via `TokenStore` — jangan ubah mekanisme penyimpanannya.
- Token FCM penuh TIDAK PERNAH tampil di UI/log; hanya `PushService.previewToken` (12 karakter + `...`).
- Handler background FCM tetap top-level + `@pragma('vm:entry-point')`; tanpa `BuildContext`/provider.
- Gerbang kualitas tiap task: `flutter analyze` → `No issues found!`; task akhir: `flutter test` → semua lulus.
- Copy UI dalam Bahasa Indonesia; komentar kode mengikuti gaya existing (Bahasa Indonesia).
- Dependensi baru hanya: `path_provider` dan `path`.

## Review Focus

1. **Login tanpa internet** → user melihat "Tidak ada koneksi internet. Periksa jaringan Anda." (bukan stack trace). *Tes di Task 1 (connectionError lolos sebagai DioException → `friendlyError`).*
2. **Access token kedaluwarsa (1 jam), refresh masih valid** → request 401 di-refresh sekali, ulang request, pasangan token baru tersimpan — user tidak disuruh login ulang. *Tes di Task 1 (interceptor 401→refresh→retry).*
3. **Dua push dengan id sama** (milidetik sama / hash tabrakan) → keduanya tetap ada di daftar, tidak saling menimpa. *Tes di Task 3 (duplikat id).*
4. **File `notifications.json` korup** (JSON tak valid, tertulis separuh) → app tidak crash saat startup; daftar dianggap kosong. *Tes di Task 3 (file korup).*
5. **Logout saat daftar masih berisi item** → daftar ter-clear dan badge sistem kembali 0 (user berikutnya tidak melihat notifikasi user lama). *Tes di Task 5 (ProviderContainer).*

---

### Task 1: Login dummyjson — AuthRepository + interceptor

**Files:**
- Modify: `lib/data/auth_repository.dart` (rewrite)
- Modify: `lib/data/api_client.dart`
- Create: `test/fakes.dart`
- Test: `test/auth_push_test.dart`

**Interfaces:**
- Consumes: `TokenStore` (`save/readAccess/readRefresh/clear`) tidak berubah.
- Produces:
  - `AuthRepository({Dio? dio})` — Dio default: `BaseOptions(baseUrl: 'https://dummyjson.com', connectTimeout: 10s, receiveTimeout: 10s)` (Dio polos, TANPA interceptor).
  - `Future<AuthSession> login({required String username, required String password})` → `POST /auth/login` body `{'username':..., 'password':...}`; HTTP 400 → `throw AuthException('Username atau kata sandi salah.')`; error lain diteruskan apa adanya (DioException).
  - `Future<AuthSession> refresh(String refreshToken)` → `POST /auth/refresh` body `{'refreshToken': refreshToken}` → `AuthSession(access, refresh)` pasangan BARU; HTTP 4xx/5xx → `throw AuthException('Refresh token tidak valid. Silakan masuk kembali.')`.
  - `class UserProfile { const UserProfile({required this.firstName, required this.lastName, required this.email, required this.image}); final String firstName, lastName, email, image; String get fullName => '$firstName $lastName'; factory UserProfile.fromJson(Map<String, dynamic> json); }` (field di atas wajib string; `fullName` = "first last").
  - Interceptor `api_client.dart`: `baseUrl` → `'https://dummyjson.com'`; setelah refresh sukses simpan **keduanya**: `store.save(access: renewed.access, refresh: renewed.refresh)`.

- [ ] **Step 1: Baseline commit (repo belum punya commit apa pun)**

```bash
git add -A
git commit -m "chore: baseline codelab minggu 6 (mock auth + FCM + bridge iOS)"
```

- [ ] **Step 2: Buat `test/fakes.dart` + tulis tes yang gagal**

Buat `test/fakes.dart` (dipakai tes ini dan Task 5 — import dari `flutter_secure_storage` dan `dio`):

```dart
/// Dio adapter yang membalas dengan respons buatan (tanpa jaringan).
class CannedAdapter extends HttpClientAdapter {
  CannedAdapter(this.respond);
  final Future<Response<dynamic>> Function(RequestOptions options) respond;

  @override
  Future<Response<dynamic>> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      respond(options);

  @override
  void close({bool force = false}) {}
}

Dio dioCanned(
  Map<String, dynamic> Function(String path) data, {
  int status = 200,
}) {
  return Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..httpClientAdapter = CannedAdapter((options) async {
      return Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: data(options.path),
      );
    });
}
```

/// FlutterSecureStorage palsu berbasis map, supaya TokenStore asli bisa
/// diuji tanpa Keychain.
```dart
class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> map = {};

  @override
  Future<void> write({required String key, required String value}) async =>
      map[key] = value;

  @override
  Future<String?> read({required String key}) async => map[key];

  @override
  Future<void> deleteAll() async => map.clear();
}
```

(import `flutter_secure_storage`). Di `test/auth_push_test.dart`: hapus class `FakeTokenStore` dan grup `sesi & refresh` lama (mock), import `fakes.dart`, lalu ganti dengan:

```dart
group('auth dummyjson', () {
  test('login mengembalikan sepasang token', () async {
    final repo = AuthRepository(
      dio: dioCanned((_) => {'accessToken': 'ACC', 'refreshToken': 'REF'}),
    );
    final session = await repo.login(username: 'emilys', password: 'emilyspass');
    expect(session.access, 'ACC');
    expect(session.refresh, 'REF');
  });

  test('login 400 melempar AuthException dengan pesan ramah', () async {
    final repo = AuthRepository(
      dio: dioCanned((_) => {'message': 'Invalid credentials'}, status: 400),
    );
    Object? caught;
    try {
      await repo.login(username: 'x', password: 'y');
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<AuthException>());
    expect(caught.toString(), 'Username atau kata sandi salah.');
  });

  test('refresh mengembalikan pasangan token baru', () async {
    final repo = AuthRepository(
      dio: dioCanned((_) => {'accessToken': 'ACC2', 'refreshToken': 'REF2'}),
    );
    final session = await repo.refresh('REF');
    expect(session.access, 'ACC2');
    expect(session.refresh, 'REF2');
  });

  test('refresh 400 melempar AuthException (paksa login ulang)', () async {
    final repo = AuthRepository(
      dio: dioCanned((_) => {'message': 'bad'}, status: 400),
    );
    expect(
      () => repo.refresh('REF'),
      throwsA(isA<AuthException>()),
    );
  });

  test('network down diteruskan sebagai DioException (bukan AuthException)',
      () async {
    final repo = AuthRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
        ..httpClientAdapter = CannedAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }),
    );
    expect(
      () => repo.login(username: 'x', password: 'y'),
      throwsA(isA<DioException>()),
    );
  });

  test('interceptor: 401 -> refresh -> retry sekali -> sukses', () async {
    final store = TokenStore(storage: FakeSecureStorage())
      ..save(access: 'expired', refresh: 'REF');
    final authDio = dioCanned(
      (path) =>
          path.contains('/auth/refresh')
              ? {'accessToken': 'NEW', 'refreshToken': 'REF2'}
              : {},
    );
    var meCalls = 0;
    final api = buildApiClient(store, AuthRepository(dio: authDio))
      ..httpClientAdapter = CannedAdapter((options) async {
        meCalls++;
        if (meCalls == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 401,
              data: {'message': 'expired'},
            ),
          );
        }
        return Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {'id': 1},
        );
      });

    final res = await api.get<dynamic>('/users/me');

    expect(res.statusCode, 200);
    expect(meCalls, 2);
    expect(await store.readAccess(), 'NEW');
    expect(await store.readRefresh(), 'REF2');
  });
});
```

- [ ] **Step 3: Jalankan tes, pastikan GAGAL**

Run: `flutter test test/auth_push_test.dart`
Expected: FAIL — `AuthRepository` belum punya parameter `dio`, signature `login`/`refresh` belum cocok.

- [ ] **Step 4: Implementasikan** `lib/data/auth_repository.dart`

- `AuthSession` dan `AuthException` tidak berubah.
- Tambah `UserProfile` (lihat Interfaces).
- `AuthRepository({Dio? dio})` menyimpan `_dio` (default Dio polos, baseUrl dummyjson, timeout 10 dtk).
- `login`: `await _dio.post('/auth/login', data: {...})`; tangkap `DioException` ber-status 400 → `AuthException('Username atau kata sandi salah.')`; parse `accessToken`/`refreshToken` dari body.
- `refresh`: `POST /auth/refresh`; semua kegagalan → `AuthException('Refresh token tidak valid. Silakan masuk kembali.')`.
- Hapus parameter `latency` dan logika mock.

`lib/data/api_client.dart`: ubah `baseUrl` menjadi `https://dummyjson.com`; di blok refresh sukses ganti jadi:

```dart
final renewed = await auth.refresh(refreshToken);
await store.save(access: renewed.access, refresh: renewed.refresh);
```

- [ ] **Step 5: Jalankan tes + analyze**

Run: `flutter test test/auth_push_test.dart && flutter analyze`
Expected: semua PASS, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/data/auth_repository.dart lib/data/api_client.dart test/auth_push_test.dart
git commit -m "feat: login & refresh dummyjson + interceptor simpan pasangan token baru"
```

---

### Task 2: Form login username + profil user di Home

**Files:**
- Modify: `lib/pages/login_page.dart`
- Modify: `lib/providers/auth_provider.dart`
- Modify: `lib/pages/home_page.dart`
- Test: `test/auth_push_test.dart`

**Interfaces:**
- Consumes: `UserProfile.fromJson`, `apiClientProvider`, `authStateProvider` (Task 1/existing).
- Produces:
  - `userProfileProvider = FutureProvider<UserProfile?>` — `null` bila tidak login atau fetch gagal.
  - `AuthNotifier.login(String username, String password)` (nama parameter lama `email` diganti).

- [ ] **Step 1: Tulis tes `UserProfile.fromJson` yang gagal** di `test/auth_push_test.dart`

```dart
group('UserProfile', () {
  test('membaca field dan menyusun nama lengkap', () {
    final p = UserProfile.fromJson({
      'firstName': 'Emily',
      'lastName': 'Johnson',
      'email': 'emily@x.com',
      'image': 'https://example.com/i.png',
    });
    expect(p.fullName, 'Emily Johnson');
    expect(p.email, 'emily@x.com');
  });
});
```

- [ ] **Step 2: Jalankan, pastikan GAGAL** (factory belum ada)

Run: `flutter test test/auth_push_test.dart`
Expected: FAIL — `fromJson` undefined.

- [ ] **Step 3: Implementasikan**

- `UserProfile.fromJson` di `lib/data/auth_repository.dart` (cast string untuk keempat field).
- `lib/providers/auth_provider.dart`:
  - Parameter `AuthNotifier.login` → `username`.
  - Tambah:

```dart
/// Profil user yang sedang login (bukti token Bearer bekerja).
/// `null` bila tidak login atau fetch gagal — UI memakai sapaan netral.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final loggedIn = await ref.watch(authStateProvider.future);
  if (!loggedIn) return null;
  try {
    final res = await ref.watch(apiClientProvider).get<dynamic>('/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});
```

- `lib/pages/login_page.dart`:
  - `TextEditingController` default: `'emilys'` dan `'emilyspass'`.
  - Label field pertama: `Username` (bukan Email); ikon `Icons.person_outline`; validator: cukup non-empty (`'Username wajib diisi'`).
  - Panggilan notifier: `login(_email.text.trim(), _password.text)` — nama variabel controller boleh tetap `_username` (rename agar jelas).
- `lib/pages/home_page.dart`: di atas `_StatusCard`, tambah kartu sapaan:

```dart
final profile = ref.watch(userProfileProvider).valueOrNull;
// ...
Card(
  child: ListTile(
    leading: const Icon(Icons.person_outline),
    title: Text(profile?.fullName ?? 'Mahasiswa'),
    subtitle: Text(profile?.email ?? 'Profil belum dimuat'),
  ),
),
const SizedBox(height: 16),
```

(import `userProfileProvider` dari `auth_provider.dart`).

- [ ] **Step 4: Jalankan tes + analyze**

Run: `flutter test test/auth_push_test.dart && flutter analyze`
Expected: PASS, `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/pages/login_page.dart lib/pages/home_page.dart lib/providers/auth_provider.dart lib/data/auth_repository.dart test/auth_push_test.dart
git commit -m "feat: form login username dummyjson + sapaan profil di Home"
```

---

### Task 3: NotificationStore (file JSON) + provider

**Files:**
- Create: `lib/data/notification_store.dart`
- Create: `lib/providers/notification_provider.dart`
- Modify: `pubspec.yaml`
- Test: `test/notification_store_test.dart`

**Interfaces:**
- Consumes: `path_provider` (`getApplicationDocumentsDirectory`).
- Produces:
  - `class StoredNotification { const StoredNotification({required this.id, required this.title, required this.body, required this.route, required this.createdAt}); final String id; final String title; final String body; final String route; final DateTime createdAt; Map<String, dynamic> toJson(); factory StoredNotification.fromJson(Map<String, dynamic> json); }` — `createdAt` disimpan sebagai ISO-8601 string.
  - `class NotificationStore { NotificationStore.withFile(File file); static Future<NotificationStore> create(); final ValueNotifier<List<StoredNotification>> items; Future<void> load(); Future<void> add(StoredNotification n); Future<void> remove(String id); Future<void> clear(); }`
    - `create()` → hanya me-resolve file `notifications.json` di `getApplicationDocumentsDirectory()` (**belum load** — `init()` Notifier yang load, agar store hasil injeksi tes ikut ter-load).
    - `load()` → file hilang = daftar kosong; **JSON korup = daftar kosong** (tidak boleh lempar).
    - `add()` → prepend; bila id sudah dipakai, id baru diberi akhiran `-2`, `-3`, dst. sampai unik.
    - `add/remove/clear` selalu menulis ulang file DAN memperbarui `items`.
  - `notificationsProvider = NotifierProvider<NotificationsNotifier, List<StoredNotification>>`
  - `class NotificationsNotifier extends Notifier<List<StoredNotification>> { NotificationStore? _store; Future<void> init(); Future<void> add(StoredNotification n); Future<void> remove(String id); Future<void> clearAll(); }` — `init()` idempoten: `_store ??= await NotificationStore.create(); await _store!.load(); state = _store!.items.value;`

- [ ] **Step 1: Tambah dependensi** di `pubspec.yaml`

```yaml
  path_provider: ^2.1.4
  path: ^1.9.0
```

Run: `flutter pub get` — Expected: sukses.

- [ ] **Step 2: Tulis tes yang gagal** di `test/notification_store_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:campus_notify/data/notification_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('notif_store_test');
    file = File('${tmp.path}/notifications.json');
  });

  tearDown(() async => tmp.delete(recursive: true));

  StoredNotification make(String id) => StoredNotification(
        id: id,
        title: 'Judul $id',
        body: 'Isi $id',
        route: '/pengumuman/$id',
        createdAt: DateTime(2026, 11, 2, 10, 0),
      );

  test('add menyimpan ke file dan bisa dibaca ulang (persist)', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('3'));

    final again = NotificationStore.withFile(file);
    await again.load();
    expect(again.items.length, 1);
    expect(again.items.first.id, '3');
    expect(again.items.first.route, '/pengumuman/3');
  });

  test('add newest-first', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('1'));
    await store.add(make('2'));
    expect(store.items.map((e) => e.id).toList(), ['2', '1']);
  });

  test('id duplikat diberi akhiran unik', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('7'));
    await store.add(make('7'));
    expect(store.items.map((e) => e.id).toList(), ['7-2', '7']);
  });

  test('remove menghapus satu item dan menulis ulang file', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('1'));
    await store.add(make('2'));
    await store.remove('1');

    expect(store.items.map((e) => e.id).toList(), ['2']);
    final again = NotificationStore.withFile(file);
    await again.load();
    expect(again.items.length, 1);
  });

  test('clear mengosongkan daftar dan file', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('1'));
    await store.clear();
    expect(store.items, isEmpty);
    final again = NotificationStore.withFile(file);
    await again.load();
    expect(again.items, isEmpty);
  });

  test('file hilang -> daftar kosong, tanpa error', () async {
    final store = NotificationStore.withFile(file);
    await store.load();
    expect(store.items, isEmpty);
  });

  test('file JSON korup -> daftar kosong, tanpa error', () async {
    file.writeAsStringSync('{"id": "1", rusak');
    final store = NotificationStore.withFile(file);
    await store.load();
    expect(store.items, isEmpty);
  });

  test('round-trip JSON mempertahankan createdAt', () async {
    final n = make('9');
    final back =
        StoredNotification.fromJson(jsonDecode(jsonEncode(n.toJson())));
    expect(back.createdAt, n.createdAt);
  });
}
```

- [ ] **Step 3: Jalankan, pastikan GAGAL**

Run: `flutter test test/notification_store_test.dart`
Expected: FAIL — file/class belum ada.

- [ ] **Step 4: Implementasikan** `lib/data/notification_store.dart`

- `StoredNotification`: `toJson` → `{'id','title','body','route','createdAt': createdAt.toIso8601String()}`; `fromJson` sebaliknya (`DateTime.parse`).
- `NotificationStore`:
  - `_save()` → `jsonEncode(items.value)` ditulis ke file (atomic cukup: tulis langsung; ukuran kecil).
  - `load()` → `existsSync()` ? baca : `[]`; bungkus parse `try/catch (_) => const []` (kondisi korup — Review Focus #4).
  - `add()` → hitung akhiran unik: `var candidate = n.id; var i = 2; while (items.value.any((e) => e.id == candidate)) { candidate = '${n.id}-$i'; i++; }` lalu prepend + `_save()`.
- `lib/providers/notification_provider.dart`: `NotificationsNotifier` sesuai Interfaces; `init()` disimpan `_store ??= await NotificationStore.create()`, lalu `state = _store!.items.value`. `add/remove/clearAll` delegasi ke store lalu sinkronkan `state`.

- [ ] **Step 5: Jalankan tes + analyze**

Run: `flutter test test/notification_store_test.dart && flutter analyze`
Expected: semua PASS, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/notification_store.dart lib/providers/notification_provider.dart test/notification_store_test.dart
git commit -m "feat: NotificationStore file JSON + provider daftar notifikasi"
```

---

### Task 4: Koneksi push → daftar, halaman Notifikasi, ikon bel, suara

**Files:**
- Create: `lib/pages/notifications_page.dart`
- Modify: `lib/messaging/push_service.dart`
- Modify: `lib/routes.dart`
- Modify: `lib/providers/router_provider.dart`
- Modify: `lib/pages/home_page.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `StoredNotification`, `notificationsProvider`/`NotificationsNotifier` (Task 3), `PushService.showLocal/listenForeground/handleTerminated/handleBridgeInitial` (existing).
- Produces:
  - `PushService.onIncoming` — `void Function(StoredNotification)?`; dipanggil: (a) di `showLocal` setelah banner tampil, (b) di `onMessageOpenedApp` (FCM), (c) di `handleTerminated` (initial FCM), (d) di bridge `opened`/`getInitialPayload`.
  - `PushService.dismissLocal(int id)` → `_local.remove(id)`; `id` non-positif diabaikan.
  - `Routes.notifications = '/notifikasi'`.
  - `NotificationsPage` (konstruktor konstan).

- [ ] **Step 1: Implementasikan `push_service.dart`**

- Tambah field `void Function(StoredNotification)? onIncoming;` (import `../data/notification_store.dart`).
- Helper privat:

```dart
StoredNotification _fromRemote(RemoteMessage m) => StoredNotification(
      id: '${m.hashCode.abs()}',
      title: m.notification?.title ?? 'Pengumuman',
      body: m.notification?.body ?? '',
      route: routeFromMessage(m.data),
      createdAt: DateTime.now(),
    );
```

- Di `showLocal`: setelah `_local.show(...)`, panggil `onIncoming?.call(StoredNotification(id: '$id', title: title, body: body, route: route, createdAt: DateTime.now()));`.
- Di `listenForeground` → `onMessageOpenedApp.listen`: sebelum `go(...)`, `onIncoming?.call(_fromRemote(message));`.
- Di `handleTerminated`: bila `initial != null`, `onIncoming?.call(_fromRemote(initial));` sebelum `go(...)`.
- Di `listenBridge`: kasus `BridgePushEventType.opened` dan `getInitialPayload` (di `handleBridgeInitial`) → buat `StoredNotification` dari `event.payload`/`initial` (id: `'${payload.hashCode.abs()}'`) lalu `onIncoming?.call(...)`.
- Tambah `Future<void> dismissLocal(int id) async { if (id <= 0) return; await _local.remove(id); }`.
- **Suara**: di `showLocal`, ganti `iOS: DarwinNotificationDetails()` menjadi `iOS: const DarwinNotificationDetails(playSound: true)`. Android TIDAK diset `sound` eksplisit: channel `Importance.high` sudah memutar suara default sistem — menyetel `RawResourceAndroidNotificationSound('default')` berisiko menunjuk resource yang salah; biarkan default (tulis komentar satu baris alasannya di kode).

- [ ] **Step 2: Tambah rute + halaman daftar**

- `lib/routes.dart`: `static const String notifications = '/notifikasi';`
- `lib/providers/router_provider.dart`: tambah `GoRoute(path: Routes.notifications, builder: (context, state) => const NotificationsPage())` (import page-nya).
- `lib/pages/notifications_page.dart` (ConsumerWidget):
  - `AppBar(title: Text('Notifikasi'), actions: [bila daftar tak kosong: `IconButton(Icons.delete_sweep_outlined)` → confirm `AlertDialog` → `clearAll()`])`.
  - `final items = ref.watch(notificationsProvider);`
  - Kosong → `ListView(children: [ SizedBox(height: 120), Icon(Icons.notifications_none, size: 48), SizedBox(16), Text('Belum ada notifikasi.') ])` terpusat.
  - Item → `ListTile(leading: Icon(Icons.notifications_active_outlined), title: Text(item.title), subtitle: Text('${item.body} · ${jam menit item.createdAt}'), onTap: () => _baca(item, context, ref))`.
  - `_baca`:

```dart
Future<void> _baca(StoredNotification item, BuildContext context, WidgetRef ref) async {
  await ref.read(notificationsProvider.notifier).remove(item.id);
  await ref.read(pushServiceProvider).dismissLocal(int.tryParse(item.id) ?? -1);
  if (context.mounted) context.go(item.route);
}
```

  - Format waktu: helper kecil privat `String _jamMenit(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';`

- [ ] **Step 3: Ikon bel + badge di Home, wiring di main**

- `lib/pages/home_page.dart`: di `AppBar.actions`, SEBELUM tombol debug:

```dart
final unread = ref.watch(notificationsProvider).length;
// ...
IconButton(
  tooltip: 'Notifikasi',
  onPressed: () => context.push(Routes.notifications),
  icon: Badge(
    isLabelVisible: unread > 0,
    label: Text('$unread'),
    child: const Icon(Icons.notifications_outlined),
  ),
),
```

- `lib/main.dart`, di `_bootstrapPush()` tepat setelah `await push.initLocalNotifications();`:

```dart
await ref.read(notificationsProvider.notifier).init();
push.onIncoming = (n) => unawaited(ref.read(notificationsProvider.notifier).add(n));
```

(import `unawaited` dari `dart:async`, `notificationsProvider`).

- [ ] **Step 4: analyze + smoke test manual di emulator**

Run: `flutter analyze` → Expected: `No issues found!`
Lalu `flutter run -d emulator-5554` dan uji manual:
1. Login `emilys`/`emilyspass` → Home muncul (nama profil bisa `Mahasiswa` bila fetch gagal — boleh, selama tidak crash).
2. Tekan "Tampilkan notifikasi lokal" → banner + suara muncul; kembali ke Home → angka `1` di ikon bel.
3. Buka halaman Notifikasi → ada 1 item; tap → pindah ke `/pengumuman/3`, item hilang, angka bel hilang.
4. Tutup-buka app → item (yang dibuat sebelum tutup) masih ada (persist).

- [ ] **Step 5: Commit**

```bash
git add lib/messaging/push_service.dart lib/routes.dart lib/providers/router_provider.dart lib/pages/notifications_page.dart lib/pages/home_page.dart lib/main.dart
git commit -m "feat: daftar notifikasi + ikon bel + onIncoming + suara eksplisit"
```

---

### Task 5: Badge sistem + reset saat logout

**Files:**
- Create: `lib/services/app_badge.dart`
- Modify: `android/app/src/main/kotlin/id/ac/polinema/campus_notify/MainActivity.kt`
- Modify: `lib/providers/notification_provider.dart`
- Modify: `lib/providers/auth_provider.dart`
- Test: `test/notification_provider_test.dart`

**Interfaces:**
- Consumes: `NotificationsNotifier` (Task 3/4), `AuthNotifier.logout` (existing).
- Produces: `class AppBadge { Future<void> setBadge(int count); }` — Android: MethodChannel `campus_notify/badge`, method `setBadge`, arg `{'count': count}`; iOS: `IOSFlutterLocalNotificationsPlugin().setBadgeNumber(count)`; web/diisi-`catch` → swallow semua error (badge bukan fitur fatal).

- [ ] **Step 1: Tulis tes provider yang gagal** di `test/notification_provider_test.dart`

```dart
import 'dart:io';
import 'package:campus_notify/data/notification_store.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:campus_notify/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fakes.dart';

ProviderContainer makeContainer(File storeFile) {
  // TokenStore asli + secure storage palsu: logout() tidak boleh menyentuh
  // MethodChannel sungguhan di lingkungan test.
  return ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(TokenStore(storage: FakeSecureStorage())),
    ],
  )..read(notificationsProvider.notifier).store = NotificationStore.withFile(storeFile);
}

void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('notif_prov'));
  tearDown(() async => tmp.delete(recursive: true));

  test('add -> remove -> clearAll memperbarui state', () async {
    final container = makeContainer(File('${tmp.path}/n.json'));
    addTearDown(container.dispose);
    final n = container.read(notificationsProvider.notifier);
    await n.init();

    await n.add(const StoredNotification(id: '1', title: 'a', body: 'b', route: '/', createdAt: _ts));
    expect(container.read(notificationsProvider).length, 1);

    await n.remove('1');
    expect(container.read(notificationsProvider), isEmpty);

    await n.add(const StoredNotification(id: '2', title: 'a', body: 'b', route: '/', createdAt: _ts));
    await n.clearAll();
    expect(container.read(notificationsProvider), isEmpty);
  });

  test('logout mengosongkan daftar notifikasi', () async {
    final container = makeContainer(File('${tmp.path}/n.json'));
    addTearDown(container.dispose);
    final n = container.read(notificationsProvider.notifier);
    await n.init();
    await n.add(const StoredNotification(id: '3', title: 'a', body: 'b', route: '/', createdAt: _ts));

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(notificationsProvider), isEmpty);
  });
}

const _ts = DateTime(2026, 11, 2, 10, 0);
```

- [ ] **Step 2: Jalankan, pastikan GAGAL**

Run: `flutter test test/notification_provider_test.dart`
Expected: FAIL — setter `store` belum ada; `logout` belum menyentuh daftar. (`AppBadge.setBadge` boleh memanggil MethodChannel yang tak terdaftar — implementasinya **wajib swallow** semua error, sehingga aman di test.)

- [ ] **Step 3: Implementasikan**

- `lib/services/app_badge.dart`: sesuai Interfaces (Platform check `kIsWeb`/`Platform.isAndroid`/`Platform.isIOS`; seluruh body dalam `try/catch (_) {}`).
- `NotificationsNotifier`: tambahkan akses store untuk tes (Dart memprivatkan underscore per-library, jadi harus publik + anotasi):

```dart
NotificationStore? _store;

@visibleForTesting
NotificationStore? get store => _store;

@visibleForTesting
set store(NotificationStore? value) => _store = value;
```

(import `package:flutter/foundation.dart`). Setiap `add/remove/clearAll` setelah memperbarui `state`: `unawaited(AppBadge().setBadge(state.length));`
- `AuthNotifier.logout()`: sebelum `state = AsyncData(false)`, panggil `await ref.read(notificationsProvider.notifier).clearAll();` (badge ikut reset 0 karena `clearAll`).
- `MainActivity.kt`:

```kotlin
package id.ac.polinema.campus_notify

import android.content.ComponentName
import android.appwidget.AppWidgetManager
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "campus_notify/badge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setBadge" -> {
                        setBadge(call.argument<Int>("count") ?: 0)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Best-effort untuk launcher bermerek (Samsung/Xiaomi/Oppo/Vivo).
    // Launcher Google standar (termasuk emulator) tidak menampilkan badge
    // aplikasi — ini batasan launcher, bukan bug.
    private fun setBadge(count: Int) {
        val manager = AppWidgetManager.getInstance(this)
        val widgetId = manager
            .getAppWidgetIds(ComponentName(this, MainActivity::class.java))
            .firstOrNull() ?: 1
        sendBroadcast(
            Intent("android.appwidget.action.APPWIDGET_UPDATE").apply {
                setPackage(packageName)
                putExtra("appWidgetId", widgetId)
            }
        )
        sendBroadcast(
            Intent("$packageName.BADGE_COUNT").apply {
                putExtra("badge_count", count)
                putExtra("app_badge_count", count)
            }
        )
    }
}
```

- [ ] **Step 4: Jalankan semua tes + analyze + build Android**

Run: `flutter test && flutter analyze`
Expected: semua PASS, `No issues found!`
Run: `flutter build apk --debug` — Expected: sukses (Kotlin terkompilasi).

- [ ] **Step 5: Commit**

```bash
git add lib/services/app_badge.dart android/app/src/main/kotlin lib/providers/notification_provider.dart lib/providers/auth_provider.dart test/notification_provider_test.dart test/fakes.dart
git commit -m "feat: badge sistem (Android broadcast + iOS) + reset saat logout"
```

---

### Task 6: Setup Firebase via browser + uji push nyata

**Files:**
- Create: `android/app/google-services.json` (diunduh via Firebase Console)

**Interfaces:**
- Consumes: seluruh jalur FCM existing di `main.dart`/`push_service.dart` (sudah ada — tidak ada perubahan kode Dart).
- Produces: FCM token aktif di emulator + push dari Firebase Console sampai (banner + suara + masuk daftar).

- [ ] **Step 1: Buat project Firebase lewat browser (MCP Brave)**

1. Navigasikan browser ke `https://console.firebase.google.com`.
2. Bila belum login: minta pengguna login dengan akun Google-nya (jeda sampai halaman project list muncul).
3. **Add project** → nama bebas (mis. `campus-notify`) → Analytics boleh dimatikan → **Create project**.
4. Di halaman project: ikon **Android** → package name **persis `id.ac.polinema.campus_notify`** → Register → unduh `google-services.json`.

- [ ] **Step 2: Taruh file & verifikasi token**

Simpan file ke `android/app/google-services.json` (plugin `com.google.gms.google-services` otomatis aktif — `android/app/build.gradle.kts` baris 10–12 sudah mengecek keberadaan file).

Run: `flutter run -d emulator-5554` (restart penuh, bukan hot reload)
Expected: halaman Debug (`/debug`) menampilkan token preview 12 karakter + `...` (status `FCM siap`). Bila token tetap `null`: image emulator butuh Google Play Services — ganti AVD ke image `google_apis_playstore`.

- [ ] **Step 3: Kirim push beneran dari Firebase Console (via browser)**

Messaging → Create campaign → tab **Notification** → isi judul/body → **Additional options → Custom data**: `{"route": "/pengumuman/3", "id": "3"}` → kirim ke token emulator.
Expected di emulator: banner + suara; item masuk daftar Notifikasi; angka badge bertambah; tap item → `/pengumuman/3` + item hilang.

- [ ] **Step 4: Commit**

```bash
git add android/app/google-services.json
git commit -m "chore: firebase project campus-notify (android app)"
```

---

### Task 7: README + gerbang akhir

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: hasil Task 1–6.
- Produces: dokumen konsisten + verifikasi penuh hijau.

- [ ] **Step 1: Perbarui `README.md`**

- "Login demo": ganti penjelasan mock → API dummyjson (`https://dummyjson.com`), kredensial `emilys`/`emilyspass`, token access 1 jam + refresh 30 hari, alur 401→refresh nyata.
- Tambah bagian "Daftar notifikasi, badge, dan suara": sumber pengisian (`PushService.onIncoming`), perilaku "dibaca = hilang", badge dalam app vs badge sistem (catatan launcher standar), suara (default channel Android / `playSound` iOS).
- "Mengaktifkan FCM": sempurnakan dengan langkah register app + link project; catat bahwa `POST /devices` akan 404 di dummyjson (sengaja, bagian codelab).
- Struktur folder: tambah `notification_store.dart`, `notification_provider.dart`, `notifications_page.dart`, `services/app_badge.dart`.
- Tabel pengujian: tambah baris daftar/badge/suara.

- [ ] **Step 2: Gerbang akhir**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` + `All tests passed!`

Scenario lengkap di emulator (manual, dicatat hasilnya di README):
1. Login → Home menampilkan nama profil.
2. Push dari Firebase Console → banner + suara + masuk daftar + badge.
3. Tap item daftar → pengumuman terbuka, item hilang, badge berkurang.
4. Restart app → sisa daftar masih ada.
5. Logout → daftar kosong, badge 0, kembali ke halaman login.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: README login API + daftar notifikasi + badge + suara + Firebase"
```
