# app_mahasiswa

Aplikasi Flutter Course Minggu 6: Implementasi REST API menggunakan **Dio** dan **Riverpod**.

---

## Hasil Pemeriksaan Kode AI (Checklist Verifikasi Teknis)

Berikut adalah catatan hasil audit dan verifikasi teknis terhadap kode yang dihasilkan oleh AI sesuai panduan *Periksa sebelum kode AI diterima*:

| No | Poin Pemeriksaan | Status | Temuan & Bukti Implementasi |
|:---:|:---|:---:|:---|
| **1** | **UI memanggil Dio langsung (dilarang) atau lewat repository?** | **Lolos (Lewat Repository)** | UI (`post_list_page.dart`) hanya berinteraksi dengan Riverpod Provider (`pagedPostsProvider`, `commentsProvider`). Provider berkomunikasi dengan `PostRepository` / `CommentRepository`, dan hanya repository yang mengakses instance `Dio`. Tidak ada kode UI yang memanggil `Dio` secara langsung. |
| **2** | **fromJson aman null, atau masih cast langsung yang bisa crash?** | **Lolos (Aman Null)** | Di `Comment.fromJson` ([`lib/data/models/comment.dart`](lib/data/models/comment.dart)), parsing menggunakan casting aman dan fallback operator null-coalescing (`??`), misalnya:<br>`postId: (json['postId'] as num?)?.toInt() ?? 0`<br>`name: json['name'] as String? ?? ''`<br>Jika backend mengembalikan nilai `null`, field hilang, atau tipe angka tidak presisi (`double/num`), aplikasi **tidak akan crash**. |
| **3** | **Semua DioExceptionType (timeout, connectionError, badResponse) dipetakan?** | **Lolos (Lengkap)** | Di [`lib/data/api_client.dart`](lib/data/api_client.dart), fungsi `friendlyErrorMessage` menangani secara komprehensif:<br>- `connectionTimeout`, `sendTimeout`, `receiveTimeout` &rarr; pesan timeout.<br>- `connectionError` &rarr; pesan koneksi internet.<br>- `badResponse` &rarr; status 404, 401/403, 500 & 5xx server error.<br>- `cancel`, `badCertificate`, dan `unknown`. |
| **4** | **baseUrl & timeout terpusat di satu client, bukan tersebar?** | **Lolos (Terpusat)** | Seluruh konfigurasi `baseUrl` (`https://jsonplaceholder.typicode.com`), `connectTimeout` (10s), dan `receiveTimeout` (10s) dipusatkan di fungsi `createDio()` pada [`lib/data/api_client.dart`](lib/data/api_client.dart) dan di-expose via `dioProvider`. Semua repository mengonsumsi satu instance terpusat ini. |
| **5** | **Test menguji field hilang, bukan hanya happy path? Tambah 1 edge case sendiri.** | **Lolos (+3 Edge Cases)** | Di [`test/widget_test.dart`](test/widget_test.dart) telah diuji:<br>1. *Happy path*: JSON lengkap.<br>2. *Field hilang*: JSON `{}` kosong.<br>3. *Field sebagian hilang*: hanya ada `postId` dan `email`.<br>4. **[Edge Case 1]**: JSON dengan nilai eksplisit `null` (`{"postId": null, "name": null, ...}`).<br>5. **[Edge Case 2]**: Field ID bertipe `num`/`double` (`postId: 1.0, id: 99.0`).<br>6. **[Edge Case 3]**: `friendlyErrorMessage` untuk HTTP 503 Service Unavailable & request cancel. |
| **6** | **flutter analyze & flutter test lolos tanpa warning?** | **Lolos (0 Warning, 15/15 Pass)** | - `flutter analyze` &rarr; `No issues found! (0 warnings, 0 errors)`<br>- `flutter test` &rarr; `00:00 +15: All tests passed!` |

---

## Ringkasan Perintah Verifikasi

Untuk memverifikasi keabsahan kode:

```bash
# 1. Jalankan static analysis (wajib bersih tanpa warning)
flutter analyze

# 2. Jalankan seluruh unit tests
flutter test test/widget_test.dart --reporter=expanded
```
