# Perbandingan Storage: SharedPreferences, Hive, sqflite, dan Drift

Dokumen ini berisi hasil analisis **AI Prompt Challenge**, **AI Verification Checklist**, dan **Tabel Perbandingan Storage** untuk aplikasi **Flutter Offline Notes**.

---

## 1. AI Prompt Challenge

### Prompt yang Digunakan
```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini.
Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan, beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan. Jelaskan trade-off setiap pilihan.
```

---

## 2. AI Verification Checklist

Berikut adalah hasil verifikasi teknis berdasarkan pengujian dan implementasi langsung di aplikasi:

* **Apakah AI menempatkan daftar catatan di SharedPreferences?**
  * **Status:** ❌ **Ditolak**
  * **Temuan:** SharedPreferences hanya menyimpan data dalam bentuk Key-Value (XML/plist). Menyimpan list/koleksi catatan yang besar (JSON String) di SharedPreferences sangat rapuh, tidak efisien dalam pemakaian memori, tidak mendukung indexing, dan rawan korupsi data saat tulisan konkuren.

* **Apakah skema AI mendukung antrean sync (dirty flag / `updated_at`) atau hanya CRUD polos?**
  * **Status:** ✅ **Mendukung Sync**
  * **Temuan:** Skema yang dirancang pada `sqflite` mencakup kolom `dirty INTEGER DEFAULT 0` dan `updated_at TEXT/TIMESTAMP`. Ini sangat krusial untuk melacak catatan mana yang perlu disinkronkan ke server (offline-first sync queue).

* **Apakah klaim "real-time" AI didukung stream (`Drift.watch()`) atau hanya asumsi?**
  * **Status:** ✅ **Terverifikasi**
  * **Temuan:** Drift menyediakan fungsi `watch()` bawaan berbasis Reactive Stream. Namun, pada `sqflite`, reaktivitas dicapai dengan memadukan State Management (misal Riverpod `FutureProvider` & `invalidate`), yang terbukti sama efektifnya tanpa perlu library code generation tambahan.

* **Apakah estimasi boilerplate AI masuk akal setelah dicoba (`flutter pub add` + migrasi skema)?**
  * **Status:** ✅ **Masuk Akal**
  * **Temuan:** 
    * **SharedPreferences:** Boilerplate sangat kecil.
    * **sqflite:** Boilerplate sedang (perlu SQL DDL dan mapper `toMap`/`fromMap`).
    * **Hive:** Perlu pembentukan `TypeAdapter` dan registrasi hive box.
    * **Drift:** Boilerplate tinggi karena membutuhkan `build_runner` untuk *code generation*.

* **Keputusan Final:**
  * **Preferensi Tema / State Sederhana:** `SharedPreferences`
  * **Penyimpanan Catatan (1000+ data & Sync Queue):** `sqflite` (SQLite)

---

## 3. Tabel Perbandingan Storage

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
| :--- | :--- | :--- | :--- | :--- |
| **Kompleksitas query** | Sangat Rendah (Hanya Key-Value) | Rendah (Filtering in-memory / NoSQL) | Tinggi (Mendukung SQL SELECT, WHERE, ORDER BY, INDEX) | Sangat Tinggi (SQL Query Builder dengan Type-Safe API) |
| **Dukungan relasi** | Tidak Ada | Terbatas (HiveRelation / Manual Links) | Ya (Foreign Key, JOIN) | Ya (Foreign Key, JOIN fully typed) |
| **Reaktivitas (stream)** | Tidak Ada | Ada (`ValueListenable` / `watch()`) | Manual (dihubungkan via Riverpod/StateNotifier) | Bawaan (`watch()`, `watchSingle()`) |
| **Type-safety** | Rendah (Primitive Types) | Sedang (Membutuhkan TypeAdapter) | Sedang (Perlu Mapper `fromMap`/`toMap`) | Sangat Tinggi (Generated Data Class & Column definition) |
| **Ukuran boilerplate** | Sangat Kecil | Sedang | Sedang | Tinggi (Memerlukan `build_runner` & code generation) |
| **Kemudahan testing** | Sangat Mudah (Mocking `SharedPreferences.setMockInitialValues`) | Sedang (Perlu in-memory Hive box / Mocking) | Sangat Mudah (Gunakan in-memory DB `sqlite_async` / Fake Repository) | Sedang (Membutuhkan setup `NativeDatabase.memory()`) |
| **Cocok untuk preferensi?** | **Sangat Cocok** (Ringan, tanpa overhead DB) | Kurang Cocok (Terlalu heavy untuk key-value sederhana) | Kurang Cocok (Overhead SQL connection untuk key-value) | Kurang Cocok (Overhead schema & generator) |
| **Cocok untuk 1000+ catatan?** | **Tidak Cocok** (Serialize seluruh JSON string setiap update) | Cukup Cocok (Kinerja in-memory cepat, tapi makan RAM) | **Sangat Cocok** (Indexing SQL cepat, pagination, efisien memori) | **Sangat Cocok** (Bisa dipagination & indexed) |
| **Keputusan & Alasan** | **Dipilih untuk Preferensi Tema** (Cepat, simpel, ramah resource) | Tidak Dipilih (Kurang ideal untuk query SQL & sync queue) | **Dipilih untuk Data Catatan** (Relasional, SQL indexing, antrean sync `dirty`) | Tidak Dipilih (Terlalu banyak boilerplate code generation untuk scope ini) |

---

## 4. Skema Tabel untuk 1000+ Catatan (sqflite / SQLite)

Untuk menangani 1000+ catatan dengan performa tinggi dan mendukung antrean sinkronisasi offline, skema DDL SQLite dirancang sebagai berikut:

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 1
);

-- Indeks untuk mempercepat pencarian antrean sinkronisasi (sync queue)
CREATE INDEX idx_notes_dirty ON notes(dirty);

-- Indeks untuk pengurutan catatan berdasarkan waktu update terbaru
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
```

### Trade-off Pilihan Skema:
1. **Penyimpanan Timestamp (`updated_at`) sebagai String ISO-8601:**
   * **Kelebihan:** Mudah dibaca saat debugging dan kompaatibel lintas platform.
   * **Trade-off:** Memakan sedikit lebih banyak bytes dibanding SIMULASI UNIX Epoch Integer.
2. **Penggunaan Indeks pada `dirty` & `updated_at`:**
   * **Kelebihan:** Query pencarian `SELECT COUNT(*) FROM notes WHERE dirty = 1` dan `ORDER BY updated_at DESC` tetap dalam kecepatan `O(log N)` pada 1000+ baris data.
   * **Trade-off:** Operasi `INSERT`/`UPDATE` sedikit bertambah durasinya untuk penyesuaian indeks, tetapi tidak signifikan pada skala ribuan baris.

---

## 5. Tanggung Jawab Teknis & Kesimpulan

Mengapa kombinasi **SharedPreferences + sqflite** adalah keputusan terbaik untuk aplikasi ini?

1. **Pemisahan Tanggung Jawab (Separation of Concerns):**
   * **Preferensi Tema** (`isDarkMode`, `forceOffline`) adalah data konfigurasi berukuran sangat kecil (beberapa bit/boolean). **SharedPreferences** mengeksekusinya secara efisien tanpa butuh koneksi ke file database.
   * **Data Catatan** (`title`, `body`, `updated_at`, `dirty`) adalah data terstruktur yang tumbuh beriringan dengan aktivitas pengguna. **sqflite** menyediakan kapasitas query SQL lengkap, pengurutan efisien, serta ketahanan data saat aplikasi mati mendadak (*crash resilience*).

2. **Fleksibilitas Tanpa Dependency Lock-in (Code Generation):**
   * Menggunakan **sqflite** menghindari keharusan menjalankan `flutter pub run build_runner build` setiap kali ada perubahan atribut kecil pada model data (berbeda dengan Drift/Hive TypeAdapter), sehingga siklus pengembangan dan waktu kompilasi (*build time*) aplikasi menjadi jauh lebih cepat.
