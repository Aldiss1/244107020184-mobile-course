<?php

use App\Http\Controllers\Api\MahasiswaController;
use Illuminate\Support\Facades\Route;

// Satu baris ini membuat 5 route CRUD sekaligus
Route::apiResource('mahasiswa', MahasiswaController::class);
