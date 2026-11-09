# Keputusan Arsitektur (ADR)

Daftar Architecture Decision Record proyek Campus Notify. Setiap ADR mencatat
konteks, keputusan, alternatif yang ditolak, dan konsekuensinya.

| # | Keputusan | Status |
|---|---|---|
| [ADR-001](ADR-001-secure-storage-untuk-token.md) | Token disimpan di `flutter_secure_storage`, bukan `SharedPreferences` | Accepted |
| [ADR-002](ADR-002-refresh-once-interceptor.md) | Refresh-once interceptor pada Dio (anti-loop 401) | Accepted |
| [ADR-003](ADR-003-single-source-rute.md) | Satu sumber konstanta rute untuk GoRouter dan payload FCM | Accepted |
| [ADR-004](ADR-004-dua-jalur-push.md) | Dua jalur push: FCM bila terkonfigurasi, jembatan native untuk iOS Simulator | Accepted |
| [ADR-005](ADR-005-arsitektur-berlapis-riverpod.md) | Arsitektur berlapis `data/domain/presentation` dengan Riverpod | Accepted |
| [ADR-006](ADR-006-route-parser-murni.md) | `routeFromMessage()` sebagai fungsi murni yang terpisah | Accepted |

## Siklus status

```
PROPOSED → ACCEPTED → (SUPERSEDED atau DEPRECATED)
```

ADR lama tidak dihapus — saat keputusan berubah, tulis ADR baru yang
mereferensikan dan meng-*supersede* yang lama.
