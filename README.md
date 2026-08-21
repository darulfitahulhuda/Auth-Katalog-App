# Auth-Katalog App

> Take-home technical test — Mobile App Developer (Flutter).
> App katalog produk dengan **auth sungguhan**: login → token di secure storage →
> dio interceptor **auto-refresh single-flight** → katalog + detail + profil.

## Cara Run

```bash
# 1. Install dependencies
flutter pub get

# 2. Regenerate codegen (freezed / json_serializable), kalau ada model berubah
dart run build_runner build --delete-conflicting-outputs

# 3. Jalankan (ganti target sesuai device)
flutter run                # deteksi device otomatis
```

**Kredensial test:** username `emilys` / password `emilyspass`
(API dummyjson, `expiresInMins: 1` sengaja biar access token cepat
kadaluarsa → memaksa alur refresh kepakai).


## Fitur

| Layar | Apa | Endpoint |
|-------|-----|----------|
| Login | form username+password, token simpan di `flutter_secure_storage` | `POST /auth/login` |
| Home | header profil, search debounce 400ms, grid produk paginated, pull-to-refresh, Rupiah | `GET /auth/me`, `GET /products`, `GET /products/search?q=` |
| Detail | gambar (Hero), judul, deskripsi, harga Rupiah, rating, stok, kategori | `GET /products/{id}` |
| Profile | kartu avatar M3, **switch tema** (light/dark/system, persist), logout confirm | `GET /auth/me` |

Setiap fetch punya state **loading / empty / error+"Coba Lagi"** + pull-to-refresh,
dan membedakan **"no internet"** vs **server error**. Semua warna mengikuti
Material 3 `colorScheme` (light & dark theme).

## Cara kerja Single-Flight Refresh

Token access punya umur pendek (`expiresInMins: 1`). Saat request protected
dipanggil dengan token expired, server balas `401`. Flow di
`lib/core/network/interceptors/auth_interceptor.dart`:

1. **Suntik token** — setiap request protected diberi header
   `Authorization: Bearer <accessToken>`.
2. **Tangkap 401** — kalau status `401` (dan bukan `/auth/login` karena
   `/auth/refresh`), interceptor mengambil alih.
3. **Single-flight lock** — hanya request pertama yang kena 401 yang memanggil
   `POST /auth/refresh`. Request lain yang gagal bersamaan **tidak** me-refresh
   sendiri; mereka menunggu `Completer` yang sama.
4. **Retry transparan** — setelah refresh sukses, token baru disimpan, seluruh
   request yang mengantre di-retry dengan token baru. User tidak perlu login
   ulang.
5. **Refresh gagal** → clear secure storage → logout → balik ke Login.

```
3 req concurrent  → 401 (×3)  →  /auth/refresh ×1  →  retry ×3 → 200
                    └── semua nunggu Completer yang sama ────────┘
```

Karena refresh memakai `.dio` instance terpisah tanpa interceptor ini,
refresh tidak pernah rekursif.

**Terbukti oleh test:** `test/single_flight_test.dart` menembakkan 3 request
protected barengan dalam kondisi 401, meng-assert `/auth/refresh` dipanggil
**tepat 1×** dan semua request di-retry & sukses.

## Arsitektur & Keputusan

- **Clean Architecture feature-first** — `lib/core/` (shared) + `lib/features/*/{data,domain,presentation}`.
- Dependency rule: `presentation → domain ← data`. `domain` murni Dart (tanpa
  Flutter/Dio/JSON). Layout & aturan boundary di [`docs/architecture.md`](docs/architecture.md).
- **Riverpod** (`AsyncNotifier`) sebagai state management; UI **hanya** lewat
  Use Cases / Domain Entities. Tanpa Dio / parsing JSON di widget.
- **Dio** satu-satunya di `data/datasource/`. Interceptor auth dipasang level
  `core/network`.
- **Token** di `flutter_secure_storage` (bukan SharedPreferences). Theme
  preference (non-sensitive) pakai `SharedPreferences`.
- **Model freezed + json_serializable** (codegen) — alasan: boilerplate JSON
  minimal, equality & copyWith gratis, instance yang jelas per entity. Entity
  domain tetap murni (tanpa `fromJson`).
- **Money-path** — harga format Rupiah (pemisah ribuan) via
  `RupiahExtension` di `core/extension/`.

## Testing

```bash
flutter analyze   # harus bersih
flutter test
```

| Test | Apa yang dijamin |
|------|------------------|
| `single_flight_test.dart` | 3×401 barengan → refresh **tepat 1×** → semua retry sukses, token terganti, tidak ada bounce login |
| `profile_repo_test.dart` | repo profil mem-parsing response `/auth/me` asli dummyjson |

## Estimasi Pengerjaan

± 2 hari kalender, termasuk setup clean architecture,
single-flight interceptor + test-nya, tema M3 light/dark, dan polish UX.

## Yang Mau Diperbaiki / Next Steps

- **Widget test** lebih luas — login form (salah kredensial → error tampil),
  empty state search, error+retry, theme switch dialog.
- **Offline live indicator** — memakai `connectivity_plus` untuk snackbar
  "offline" real-time, bukan hanya error view saat fetch gagal.
- **Share produk**, share nama, harga, dsb. demi kelengkapan
  UX katalog.
- **Bahasa**, multi languages
