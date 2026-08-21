# Auth-Katalog App

> Technical Test — Mobile App Developer (Flutter). Take-home untuk kandidat.
> Test ini sengaja mencerminkan bagian tersulit & terpenting dari aplikasi kami: auth
> token + dio interceptor + auto-refresh (single-flight) + money-path + state async.
> Kalau kamu job-ready, ini ~sehari kerja. Kalau kamu harus belajar
> Riverpod/dio/refresh-token dari nol, test ini akan terasa berat — dan memang itu yang
> ingin kami saring.

- **Judul:** "Auth-Katalog App" (Flutter)
- **Estimasi:** 6–10 jam kerja · Deadline kumpul: 5 hari setelah test diterima.
- **Boleh pakai:** package apa pun yang wajar (riverpod, dio, freezed,
  flutter_secure_storage, dll) + dokumentasi API.
- **Tidak boleh:** copy project jadi / pakai template auth orang lain tanpa paham. Saat
  interview kamu wajib bisa menjelaskan tiap baris.
- **API:** https://dummyjson.com (gratis, ada auth sungguhan)
- **Dokumentasi:** https://dummyjson.com/docs/auth — verifikasi field terbaru di sana
  sebelum ngoding.

## Endpoints

| # | Method & path | Request | Response |
|---|---------------|---------|----------|
| 1 | `POST /auth/login` | `{ "username": "emilys", "password": "emilyspass", "expiresInMins": 1 }` | 200: `{ "id": 1, "username": "emilys", "accessToken": "<JWT>", "refreshToken": "<JWT>", ... }` |
| 2 | `POST /auth/refresh` | `{ "refreshToken": "<refreshToken>" }` | `{ "accessToken": "<JWT baru>", "refreshToken": "<JWT baru>", "expiresInMins": 1 }` |
| 3 | `GET /auth/me` (protected) | header `Authorization: Bearer <accessToken>` | 200: profil user; 401 kalau token kadaluarsa/absen (pemicu refresh) |
| 4 | `GET /products?limit=20&skip=0` · `GET /products/search?q=<kw>` · `GET /products/{id}` | — | daftar / hasil cari / detail katalog |

**Kredensial test:** username `emilys` / password `emilyspass`.

⚠ Pakai `expiresInMins: 1` SENGAJA supaya access token cepat kadaluarsa → memaksa alur
refresh kepakai.

## Requirements (acceptance criteria — semua wajib kecuali BONUS)

### Part 1 — Login + penyimpanan token aman
- Layar login (username + password) → `POST /auth/login` (kirim `expiresInMins: 1`).
- Simpan accessToken + refreshToken di flutter_secure_storage (bukan SharedPreferences).
- **Acceptance:** login benar → masuk Home; login salah → pesan error jelas; token
  tersimpan; saat app dibuka ulang & token masih ada → langsung ke Home (auto-login).

### Part 2 — dio Interceptor + Auto-Refresh Single-Flight
- Interceptor menyisipkan `Authorization: Bearer <accessToken>` ke setiap request protected.
- Saat request protected balik 401 → interceptor memanggil `POST /auth/refresh` → simpan
  token baru → retry request semula secara transparan (user tidak perlu login ulang).
- **SINGLE-FLIGHT:** jika beberapa request protected kena 401 bersamaan, refresh hanya
  boleh jalan SEKALI; request lain antri menunggu hasil refresh, lalu semua di-retry.
- Jika refresh gagal (refresh token invalid) → clear storage → balik ke layar login.
- **Acceptance (runtime):** karena `expiresInMins: 1`, tunggu >1 menit lalu lakukan aksi
  yang memicu fetch protected → data tetap muncul tanpa user login ulang.
- **Acceptance (WAJIB, via test):** unit test menembakkan ≥3 request protected berbarengan
  dalam kondisi 401, lalu meng-assert: `/auth/refresh` dipanggil **tepat 1×**, dan semua
  request di-retry dan sukses. (Pakai mock dio, mis. http_mock_adapter/mocktail.)

### Part 3 — Home: profil + katalog
- Fetch `GET /auth/me` (profil, protected) + `GET /products` (list, paginated / infinite scroll).
- Kartu produk: gambar (thumbnail), judul, dan harga diformat Rupiah (mis. Rp1.250.000 —
  pemisah ribuan, tabular).
- Search bar dengan debounce ~400ms → `GET /products/search?q=`.
- Pull-to-refresh.
- **Acceptance:** setiap fetch menampilkan state loading / empty / error+"Coba Lagi"
  dengan benar (bukan layar blank saat gagal).

### Part 4 — Detail
- Tap kartu → layar detail (`GET /products/{id}`): gambar, judul, deskripsi, harga
  (Rupiah), rating.

### Part 5 — Logout
- Tombol logout → dialog konfirmasi → clear secure storage → balik ke login.

### Part 6 — Arsitektur & model
- Pisahkan data layer (repository + dio + model) dan presentation (controller Riverpod +
  screen).
- Model pakai freezed + json_serializable (atau setara — jelaskan alasannya di README).
- Tidak boleh ada call API / parsing JSON langsung di dalam widget.

### BONUS (opsional, menaikkan nilai)
- Handling offline (bedakan "no internet" vs "server error"), dark theme, widget test,
  animasi transisi halus, CI (GitHub Actions `flutter analyze` + `flutter test`).

## Yang Dikumpulkan
- Repo Git (GitHub public, atau private + invite reviewer) dengan histori commit wajar
  (bukan 1 commit besar).
- README memuat: cara run, penjelasan bagaimana single-flight refresh bekerja, keputusan
  arsitektur, waktu pengerjaan, dan "kalau ada waktu lebih, yang mau diperbaiki".
- Output `flutter analyze` bersih (tanpa error).

## Rubrik Penilaian (total 100)

| Bobot | Aspek | Lulus jika… |
|------|-------|-------------|
| 30 | Auth + refresh single-flight | Refresh transparan jalan; single-flight terbukti (refresh 1× untuk N request 401 barengan) + ada unit test-nya; refresh gagal → logout bersih |
| 20 | Arsitektur & Riverpod | data/presentation terpisah; Riverpod dipakai benar; tidak ada logic API di widget |
| 15 | State UI | loading/empty/error+retry lengkap di semua fetch + pull-refresh |
| 15 | Money-path & UX | format Rupiah benar; search debounce; detail; logout confirm; token di secure storage |
| 10 | Kualitas kode & model | rapi, null-safe, freezed/json benar, konsisten |
| 10 | Testing | test yang meaningful (minimal test single-flight) |

**Batas lulus:** total ≥ 70 **DAN** Part 2 (refresh single-flight) berfungsi. Kalau Part 2
tidak jalan/tidak ada, dianggap belum job-ready — berapa pun nilai lainnya, karena inilah
pola inti di codebase kami.

### Red flags (langsung mengurangi nilai besar)
- Refresh token tidak single-flight (setiap 401 nge-refresh sendiri-sendiri → race).
- Token disimpan di SharedPreferences / plain (bukan secure storage).
- Call API / `Dio()` di-new di dalam widget; parsing JSON manual di `build()`.
- Tidak ada error/empty state (layar blank saat gagal).
- Harga hanya `price.toString()` tanpa pemisah ribuan.
- Mock/dummy data tertinggal di UI.

---

## Clean Architecture — Strict Layer Rules (MANDATORY)

Layout mengikuti `docs/architecture.md`:

```
lib/
├── core/                                   # shared infra — TIDAK boleh import fitur
└── features/<feature_name>/
    ├── data/{datasource, model, repositories}   # Dio, JSON, implementasi interface
    ├── domain/{entity, repositories, usecase}   # MURNI Dart, tanpa Flutter/JSON
    └── presentation/{providers, screen}         # UI + state; via Use Case saja
```

Dependency flow ALWAYS inward: `presentation → domain ← data`. Core dibagi untuk semua.
Tidak ada layer boleh depend ke arah luar. Aturan ini override kenyamanan — tanpa
shortcut, tanpa tight coupling, tanpa pengecualian tanpa ADR.

### Domain layer (`lib/features/*/domain/`) — MUST BE PURE
- NO imports dari `data/`, `presentation/`, `flutter/material.dart`, atau third-party —
  **kecuali pure Dart packages** (fpdart, equatable, freezed).
- `entity/` — pure business logic / data contracts only. No JSON; `fromJson`/`toJson`
  hanya di `data/model/`.
- `repositories/` — hanya abstract interface classes. No implementation, no Dio, no storage.
- `usecase/` — orchestrate domain logic, panggil repository interface saja. Jangan
  return/terima `data/` model.

### Data layer (`lib/features/*/data/`)
- Implements abstract repository interface dari `domain/repositories/`.
- `model/` — extend/map ke domain entity; entity MUST NOT tahu model
  (mis. `fromJson`/`toJson` hanya di `model/`).
- `datasource/` — raw API/database calls (Dio). Tidak ada yang lain boleh sentuh Dio.

### Presentation layer (`lib/features/*/presentation/`)
- NO direct access ke `data/` class atau datasource.
- `screen/` + `providers/` berinteraksi **strictly melalui Use Cases / Domain Entities**.
- Widget, BuildContext, state Riverpod hidup di sini — dan hanya di sini.

### Core layer (`lib/core/`)
- Utilities global, DI (`di/`), base use case (`usecase/`), error handling, network
  clients, shared extensions.
- MUST NOT import kode spesifik fitur dari `lib/features/`.

### Forbidden actions — hard stop
- NEVER import `data/` model/implementasi di dalam `presentation/` atau `domain/`.
- NEVER letakkan HTTP requests, JSON parsing, atau DB queries di `presentation/`/`domain/`.
- NEVER leak UI state (BuildContext, Widget) ke `domain/`/`data/`.
- NEVER `Dio()` di-new di dalam widget.
- Kalau sebuah perubahan melintas batas ke luar, redesign — jangan "sementara"
  langgar aturan.

---

## Architecture

Clean-architecture layering (data / domain / presentation) dengan Riverpod. Repository
interface adalah seam testability untuk single-flight refresh. Aturan: no
Dio/API/JSON di widget; money via Rupiah formatter; bedakan offline vs server error;
token di flutter_secure_storage. Layout lengkap di `docs/architecture.md`.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage labels, all default-named. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.