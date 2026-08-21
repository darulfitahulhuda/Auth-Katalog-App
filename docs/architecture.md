# Architecture — Auth-Katalog App

Clean-architecture layering with Riverpod, feature-first layout.

## Layer layout

```
lib/
├── core/                                   # shared infrastructure — no feature imports
│   ├── app/                                # app entry / root widget
│   ├── di/                                 # dependency injection wiring
│   ├── error/                              # failures + exceptions
│   ├── extension/                          # shared extensions
│   ├── network/                            # dio clients, interceptors, network_info
│   ├── router/                             # navigation
│   ├── usecase/                            # base UseCase contract
│   └── utils/                              # typedefs, formatters (Rupiah)
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── datasource/                 # raw API calls (Dio only here)
        │   ├── model/                      # JSON models; fromJson/toJson ONLY here
        │   └── repositories/               # *Impl classes implementing domain interfaces
        ├── domain/
        │   ├── entity/                     # pure business contracts (no JSON, no Flutter)
        │   ├── repositories/               # abstract interfaces ONLY
        │   └── usecase/                    # business orchestration over repository interfaces
        └── presentation/
            ├── providers/                  # Riverpod state controllers
            └── screen/                     # widgets / screens
```

## Dependency rule

`presentation → domain ← data`, and `core` is shared by all. Dependency arrows always point
inward toward `domain`. The `domain` folder is the deepest and must be pure Dart.

## Boundary rules

- **Domain is pure.** No imports from `data/`, `presentation/`, `flutter/material.dart`, or
  third-party packages (except pure Dart packages like `fpdart`, `equatable`, `freezed`).
  Entities carry no serialization.
- **Repositories** are abstract interfaces in `domain/repositories/`, implemented in
  `data/repositories/`. This interface is the seam that makes single-flight refresh testable.
- **Use cases** orchestrate domain logic, calling only repository interfaces — never Dio or
  models directly.
- **Presentation** talks to the system strictly through Use Cases and Domain Entities. No
  Dio, no HTTP, no JSON parsing, no direct access to `data/` classes.
- **Models** (data) may reference entities (domain), but entities must never reference models.
- **core** never imports feature-specific code.

## Testability seam (single-flight refresh)

The abstract repository interface in `domain/repositories/` is mocked in tests; the
interceptor's single-flight refresh (≥3 concurrent 401s → exactly one `/auth/refresh` call,
all requests retried) is asserted against mocked Dio via `http_mock_adapter`/`mocktail`.

## Money-path

All prices formatted in Rupiah (thousands separator, tabular figures) via a shared formatter
in `core`. Never `price.toString()`.

## Offline vs server error

`network_info` distinguishes "no internet" from server failure; presentation shows distinct
loading / empty / error+"Coba Lagi" states for every fetch.