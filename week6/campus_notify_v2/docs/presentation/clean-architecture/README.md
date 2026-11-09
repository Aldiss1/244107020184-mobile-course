# Slide: SOLID — Lima Prinsip dalam Bahasa Sehari-hari

Halaman statis untuk slide 6 deck *Minggu 7 · Clean Architecture*
(Pemrograman Mobile). Dibuat ulang dari deck asli sebagai HTML mandiri:
tanpa CDN, tanpa font eksternal, bisa dibuka offline.

## Cara membuka

```bash
open docs/presentation/clean-architecture/index.html
```

Atau drag file-nya ke jendela browser.

## Export PDF

`Cmd + P` → *Save as PDF*. CSS print sudah disetel ke `16in × 9in`
tanpa margin, jadi hasilnya satu halaman 16:9 yang bersih.

## Catatan desain

- Panggung berukuran tetap 16:9 dan semua ukuran memakai `cqw`
  (persen dari lebar panggung), sehingga proporsi teks tetap sama
  di 1280px maupun 1920px.
- Palet diambil dari deck asli, didefinisikan sebagai variabel CSS
  di blok `:root`:

  | Variabel   | Nilai     | Dipakai untuk                    |
  |------------|-----------|----------------------------------|
  | `--navy`   | `#16303F` | judul, nama prinsip              |
  | `--teal`   | `#3D7C8C` | lingkaran huruf S/O/L/I/D        |
  | `--slate`  | `#7B8B96` | header kolom, footer             |
  | `--brick`  | `#C0563A` | header "Gejala pelanggaran"      |
  | `--card`   | `#EDF1F4` | kartu gejala                     |

  Slide berikutnya cukup menyalin file ini dan memakai variabel yang sama
  agar seluruh deck konsisten.
- Footer sengaja memakai **Minggu 7** (mengikuti gambar slide), bukan
  Minggu 11 seperti nama file deck aslinya.
