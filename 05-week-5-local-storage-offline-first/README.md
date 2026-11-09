# Aplikasi Offline Notes (Mini Project Week 5)

Proyek ini merupakan implementasi **Aplikasi Offline Notes** berbasis **Offline-First Architecture** menggunakan Flutter, Riverpod, SQLite (`sqflite`), SharedPreferences, dan GoRouter.

---

## 📌 1. Tujuan
Aplikasi ini dibuat untuk memenuhi tugas **Mini Project Week 5 (Local Storage & Offline-First)** mata kuliah Pemrograman Mobile. Tujuan utamanya adalah:
- Menerapkan arsitektur data **Offline-First** (Cache-First untuk data server, local storage persisten untuk data buatan pengguna).
- Memisahkan data preferensi sederhana (Key-Value) dan data terstruktur berukuran besar (Relational Database).
- Mengimplementasikan antrean sinkronisasi (*Sync Queue*) menggunakan `dirty flag` dan mekanisme pemulihan konflik (*Conflict Resolution*).
- Menjaga prinsip **Clean Architecture**: UI hanya berinteraksi melalui Riverpod Provider & Repository, tanpa mengakses SQLite/SharedPreferences secara langsung.

---

## ✨ 2. Fitur Utama
1. **Preferensi Pengguna (SharedPreferences)**
   - Toggle Tema Gelap / Terang (Dark Mode) persisten.
   - Menyimpan timestamp waktu terakhir aplikasi dibuka (`last_opened`).

2. **CRUD Catatan Persisten (SQLite / `sqflite`)**
   - Tambah, Baca, Edit, dan Hapus catatan.
   - Pengurutan otomatis berdasarkan waktu pembaruan terbaru (`updated_at` DESC).
   - Penanganan 4 State UI (Loading, Empty, Error, Data Present).

3. **Arsitektur Offline-First & Sync Queue**
   - **Cache-First**: Data kiriman remote (Posts) disimpan di cache lokal dan ditampilkan secara instan meskipun tanpa internet.
   - **Dirty Flag**: Catatan lokal yang dibuat/diedit offline diberi tanda `dirty = 1`.
   - **Badge Dirty**: UI menampilkan indikator "Belum Tersinkron" (Badge Orange) pada catatan yang belum tersinkron ke server.
   - **Sinkronisasi Manual/Otomatis (`syncNotes`)**: Mengunggah catatan dirty ke server eksternal saat koneksi tersedia dan menandainya bersih (`dirty = 0`).
   - **Simulasi Mode Pesawat / Offline Force**: Saklar toggle di halaman Pengaturan untuk menguji perilaku aplikasi dalam mode offline tanpa koneksi internet.

4. **Aturan Konflik Eksplisit (Conflict Resolution)**
   - Menggunakan strategi **Last-Write-Wins (LWW)** berdasarkan perbandingan timestamp ISO-8601 `updated_at`.
   - Jika `local.updatedAt > remote.updatedAt`, versi lokal yang dipertahankan. Jika sebaliknya, versi remote yang menimpa.

5. **Pengujian & Kualitas Kode (Testing)**
   - Minimal 9 unit test lulus (`test/note_test.dart`) menguji Serialization Model Note, Provider dengan Fake Repository, Fungsi `syncNotes`, `OfflineException`, dan `resolveConflict`.
   - Bebas warning/error pada static analysis (`flutter analyze`).

6. **Dokumentasi Challenge AI**
   - Tersedia di `docs/perbandingan-storage.md` mencakup AI prompt challenge, tabel perbandingan 4 storage engine (SharedPreferences, Hive, sqflite, Drift), dan pertimbangan teknis.

---

## 🛠️ 3. Stack Teknologi
- **Framework**: Flutter (Dart SDK ^3.13.2)
- **State Management**: Flutter Riverpod (`flutter_riverpod ^3.4.3`)
- **Local Storage (Relational)**: `sqflite ^2.4.4+1` + `path ^1.9.1`
- **Local Storage (Key-Value)**: `shared_preferences ^2.5.6`
- **Networking & API**: `dio ^5.11.1`
- **Navigation & Routing**: `go_router ^18.0.2`

---

## 🚀 4. Cara Menjalankan

### Prasyarat
- Flutter SDK (v3.13.0 atau lebih baru)
- Device emulator (Android/iOS) atau browser web

### Langkah-Langkah
1. Masuk ke direktori proyek:
   ```bash
   cd 05-week-5-local-storage-offline-first
   ```

2. Unduh semua pustaka ketergantungan (*dependencies*):
   ```bash
   flutter pub get
   ```

3. Jalankan pengujian unit & analisis statis:
   ```bash
   flutter analyze
   flutter test
   ```

4. Jalankan aplikasi di emulator / device:
   ```bash
   flutter run
   ```

---

## 📊 5. Aturan Konflik yang Dipilih (Conflict Resolution Rule)

Aturan resolusi konflik yang diterapkan adalah **Last-Write-Wins (LWW)** berdasarkan `updatedAt`:

```dart
Note resolveConflict(Note local, Note remote) {
  if (local.updatedAt.isAfter(remote.updatedAt)) {
    return local; // Simpan perubahan lokal terbaru
  }
  return remote.copyWith(dirty: false); // Gunakan data remote terbaru
}
```

### Rationale:
1. **Deterministik**: Konflik diselesaikan secara konsisten tanpa membingungkan pengguna.
2. **Tanpa Data Loss Unintentional**: Perubahan paling akhir selalu dipertahankan.
3. **Sederhana & Efisien**: Tidak memerlukan overhead penanganan diff teks (seperti CRDT/Operational Transform) untuk kasus catatan teks biasa.

---

## 🧠 6. Temuan Verifikasi AI (AI Challenge Summary)

Dari eksperimen tantangan prompt AI (terdokumentasi lengkap di `docs/perbandingan-storage.md`), diperoleh temuan berikut:

1. **SharedPreferences untuk Daftar Catatan = Bad Practice**:
   - **Rekomendasi AI Ditolak**: Menyimpan list catatan JSON di SharedPreferences tidak mendukung query/indexing SQL, rawan korupsi data, dan lambat untuk dataset > 100 catatan.
   - **Solusi**: SharedPreferences hanya dipakai untuk `isDarkMode` dan `last_opened`. Daftar catatan dikelola oleh `sqflite`.

2. **Penggunaan Indeks SQLite untuk Scale 1000+ Catatan**:
   - Menambahkan `CREATE INDEX idx_notes_dirty ON notes(dirty)` dan `CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC)` memastikan pencarian query sync queue dan render list catatan tetap berkinerja O(log N).

3. **Keunggulan `sqflite` vs `Drift` untuk Tugas Ini**:
   - `sqflite` dipilih karena tidak memerlukan *code generation* (`build_runner`), sehingga menjaga waktu kompilasi tetap cepat dan struktur kode mudah dipahami.

---

## 📸 7. Screenshots & Bukti Pengujian

Tersedia di folder [`screenshots/`](screenshots/):
- **Daftar Catatan saat Offline**: Menampilkan catatan lokal saat tidak ada koneksi.
- **Badge Dirty**: Indikator "Belum Tersinkron" pada catatan yang ditambahkan dalam mode offline.
- **Setelah Sync**: Indikator dirty hilang setelah proses sinkronisasi berhasil.

---

*Dibuat oleh: Student NIM 244107020184 - Mata Kuliah Pemrograman Mobile*
