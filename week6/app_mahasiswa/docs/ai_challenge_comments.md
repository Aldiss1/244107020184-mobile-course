# AI Prompt Challenge: Repository Layer /comments

Dokumen ini disusun untuk memenuhi **Tanggung Jawab Teknis** tugas AI Prompt Challenge.

---

## 1. Prompt yang Digunakan

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id} dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError) dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

---

## 2. Output Awal AI

AI menghasilkan 3 komponen utama:

### A. Model `Comment` (`lib/data/models/comment.dart`)
- Kelas `Comment` dengan field `postId`, `id`, `name`, `email`, dan `body`.
- Menggunakan factory constructor `Comment.fromJson` dengan operator `??` untuk fallback nilai default saat field bernilai null atau tidak ada di JSON respons.

### B. Repository `CommentRepository` (`lib/data/repositories/comment_repository.dart`)
- Menerima instance `Dio` via constructor (Dependency Injection).
- Method `fetchComments(int postId)` memanggil `GET /comments?postId={id}`.
- Konfigurasi timeout diatur 10 detik (connect & receive).

### C. State Management (`lib/data/comment_providers.dart`)
- State management menggunakan Riverpod `AsyncNotifierProvider.family`.
- Error otomatis ditangkap menjadi `AsyncError`.
- Fungsi `friendlyErrorMessage` memetakan tipe-tipe `DioException` (connectionTimeout, connectionError, 404, 500) ke teks bahasa Indonesia yang ramah pengguna.

---

## 3. Perbaikan yang Dilakukan

Setelah kode awal digenerate, dilakukan beberapa perbaikan dan penyesuaian teknis:

1. **Kompatibilitas Versi Riverpod 3.x**:
   - *Isu Awal*: AI sempat mencoba mengekstend kelas `FamilyAsyncNotifier<List<Comment>, int>` yang tidak ada pada versi `flutter_riverpod: ^3.4.3`.
   - *Solusi/Perbaikan*: Di Riverpod 3.x, pattern yang benar untuk `AsyncNotifierProvider.family` adalah:
     ```dart
     class CommentsNotifier extends AsyncNotifier<List<Comment>> {
       final int postId;
       CommentsNotifier(this.postId);
       ...
     }

     final commentsProvider = AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
       (postId) => CommentsNotifier(postId),
     );
     ```
     Argumen parameter `postId` dioper ke constructor `CommentsNotifier(this.postId)`.

2. **Modularitas Helper Error**:
   - Mengintegrasikan fungsi penanganan error ke `friendlyErrorMessage` yang telah teruji di `api_client.dart` agar konsisten menangani `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, `badResponse 404`, dan `badResponse 500`.

3. **Perluasan Test Suite**:
   - Selain test `fromJson` dengan field yang hilang (kosong), ditambahkan juga test untuk:
     - `fromJson` field sebagian hilang.
     - `friendlyErrorMessage` timeout.
     - `friendlyErrorMessage` 404.
     - `friendlyErrorMessage` 500.
     - Integrasi `commentsProvider` saat data berhasil dimuat (`AsyncData`).
     - Integrasi `commentsProvider` saat repository melempar error (`AsyncError`).

---

## 4. Hasil Testing

Pengujian dijalankan menggunakan perintah:
```bash
flutter test test/widget_test.dart --reporter=expanded
```

### Log Output Terminal:
```text
00:00 +0: Unit Test Tanpa Internet (Dio + Riverpod) fromJson aman terhadap field yang hilang
00:00 +1: Unit Test Tanpa Internet (Dio + Riverpod) friendlyErrorMessage untuk connection error
00:00 +2: Unit Test Tanpa Internet (Dio + Riverpod) Provider sukses dengan repository palsu
00:00 +3: Unit Test Tanpa Internet (Dio + Riverpod) Provider error dengan repository palsu
00:00 +4: Comment — Unit Tests Comment.fromJson dengan field lengkap
00:00 +5: Comment — Unit Tests Comment.fromJson aman saat semua field hilang (JSON kosong)
00:00 +6: Comment — Unit Tests Comment.fromJson dengan field sebagian hilang
00:00 +7: Comment — Unit Tests Edge Case: Comment.fromJson aman saat field bernilai eksplisit null
00:00 +8: Comment — Unit Tests Edge Case: Comment.fromJson aman saat ID berupa num / floating point
00:00 +9: Comment — Unit Tests Edge Case: friendlyErrorMessage untuk 503 Service Unavailable dan cancel
00:00 +10: Comment — Unit Tests friendlyErrorMessage untuk timeout menghasilkan pesan yang tepat
00:00 +11: Comment — Unit Tests friendlyErrorMessage untuk 404 menghasilkan pesan yang tepat
00:00 +12: Comment — Unit Tests friendlyErrorMessage untuk 500 menghasilkan pesan yang tepat
00:00 +13: Comment — Unit Tests commentsProvider sukses mengembalikan daftar komentar
00:00 +14: Comment — Unit Tests commentsProvider error → AsyncError saat repository gagal
00:00 +15: All tests passed!
```

**Status: 15/15 Tests PASSED (100% Berhasil)**.

---

## 5. Checklist Verifikasi Teknis (Audit Sebelum Kode Diterima)

| No | Poin Pemeriksaan | Status | Temuan & Bukti Implementasi |
|:---:|:---|:---:|:---|
| **1** | UI memanggil Dio langsung (dilarang) atau lewat repository? | **Lolos** | UI hanya memanggil Riverpod provider. Repository memanggil Dio. |
| **2** | fromJson aman null, atau masih cast langsung yang bisa crash? | **Lolos** | Menggunakan `(json['postId'] as num?)?.toInt() ?? 0` dan fallback `?? ''`. |
| **3** | Semua DioExceptionType (timeout, connectionError, badResponse) dipetakan? | **Lolos** | Dipetakan lengkap di `friendlyErrorMessage` (termasuk 404, 401/403, 500 & 5xx). |
| **4** | baseUrl & timeout terpusat di satu client, bukan tersebar? | **Lolos** | Terpusat di `createDio()` dan `dioProvider`. |
| **5** | Test menguji field hilang, bukan hanya happy path? Tambah 1 edge case sendiri. | **Lolos** | Diuji dengan JSON kosong, partial, serta ditambah edge case eksplisit null, floating num ID, dan HTTP 503. |
| **6** | flutter analyze & flutter test lolos tanpa warning? | **Lolos** | `flutter analyze` 0 warnings, `flutter test` 15/15 pass. |

---

## 5. Panduan Penjelasan Kode (Persiapan Demo)

Saat sesi demo, jelaskan poin-poin berikut:

1. **`lib/data/models/comment.dart`**:
   - `(json['postId'] as int?) ?? 0`: Melakukan cast aman bertipe nullable (`int?`). Jika nilainya `null` atau kuncinya tidak ada di Map, operator null-coalescing (`??`) akan otomatis menggantinya dengan nilai default `0`. Ini mencegah runtime error `TypeError: null is not a subtype of int`.
   - Hal yang sama berlaku untuk `(json['name'] as String?) ?? ''` untuk field teks.

2. **`lib/data/repositories/comment_repository.dart`**:
   - Menerapkan **Repository Pattern**: memisahkan logika pemanggilan jaringan dari UI dan State.
   - Menggunakan Dependency Injection: `CommentRepository(this._dio)` menerima objek `Dio` dari luar, memungkinkan kita mengganti `_dio` asli dengan Mock/Fake saat testing tanpa menyentuh server JSONPlaceholder.
   - `fetchComments(int postId)` mengirim query parameter `?postId={id}`.

3. **`lib/data/comment_providers.dart`**:
   - Menggunakan `AsyncNotifierProvider.family`: `.family` memungkinkan provider menerima argumen `postId`, sehingga setiap post memiliki cache & siklus state komentarnya masing-masing.
   - State `AsyncValue` memiliki 3 kondisi:
     - `AsyncLoading`: saat fetch berjalan.
     - `AsyncData`: saat data berhasil didapat.
     - `AsyncError`: otomatis aktif jika repository melempar exception (misal `DioException`).

4. **`test/widget_test.dart`**:
   - Menggunakan `FakeCommentRepository` yang meng-override `fetchComments`.
   - Menggunakan `ProviderContainer(overrides: [...])` untuk menguji state Riverpod secara isolated tanpa perlu menjalankan aplikasi di emulator atau membutuhkan koneksi internet.
