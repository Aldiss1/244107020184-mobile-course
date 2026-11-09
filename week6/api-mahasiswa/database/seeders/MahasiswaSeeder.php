<?php

namespace Database\Seeders;

use App\Models\Mahasiswa;
use Illuminate\Database\Seeder;

class MahasiswaSeeder extends Seeder
{
    public function run(): void
    {
        Mahasiswa::create([
            'nim'   => '2341720001',
            'nama'  => 'Andi Pratama',
            'prodi' => 'D4 Teknik Informatika',
            'email' => 'andi@example.com',
        ]);
        Mahasiswa::create([
            'nim'   => '2341720002',
            'nama'  => 'Bunga Lestari',
            'prodi' => 'D4 Sistem Informasi Bisnis',
            'email' => 'bunga@example.com',
        ]);
    }
}
