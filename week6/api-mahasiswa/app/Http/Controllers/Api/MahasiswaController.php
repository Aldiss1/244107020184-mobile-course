<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Mahasiswa;
use Illuminate\Http\Request;

class MahasiswaController extends Controller
{
    // GET /api/mahasiswa
    public function index()
    {
        $data = Mahasiswa::orderBy('nama')->get();
        return response()->json([
            'success' => true,
            'message' => 'Daftar mahasiswa',
            'data'    => $data,
        ], 200);
    }

    // POST /api/mahasiswa
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nim'   => 'required|string|max:10|unique:mahasiswa,nim',
            'nama'  => 'required|string|max:100',
            'prodi' => 'required|string|max:50',
            'email' => 'required|email|unique:mahasiswa,email',
        ]);
        $mhs = Mahasiswa::create($validated);
        return response()->json([
            'success' => true,
            'message' => 'Data berhasil ditambahkan',
            'data'    => $mhs,
        ], 201);
    }

    // GET /api/mahasiswa/{id}
    public function show(Mahasiswa $mahasiswa)
    {
        return response()->json([
            'success' => true,
            'message' => 'Detail mahasiswa',
            'data'    => $mahasiswa,
        ]);
    }

    // PUT /api/mahasiswa/{id}
    public function update(Request $request, Mahasiswa $mahasiswa)
    {
        $id = $mahasiswa->id;
        $validated = $request->validate([
            'nim'   => "required|string|max:10|unique:mahasiswa,nim,$id",
            'nama'  => 'required|string|max:100',
            'prodi' => 'required|string|max:50',
            'email' => "required|email|unique:mahasiswa,email,$id",
        ]);
        $mahasiswa->update($validated);
        return response()->json([
            'success' => true,
            'message' => 'Data berhasil diperbarui',
            'data'    => $mahasiswa,
        ]);
    }

    // DELETE /api/mahasiswa/{id}
    public function destroy(Mahasiswa $mahasiswa)
    {
        $mahasiswa->delete();
        return response()->json([
            'success' => true,
            'message' => 'Data berhasil dihapus',
        ]);
    }
}
