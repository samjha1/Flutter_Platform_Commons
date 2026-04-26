# Movie Matcher

A Flutter app where multiple users build a shared "saved movies" list and discover what
they all want to watch together. Built for the Platform Commons Flutter take-home
assignment.

> **Stack at a glance:** Flutter · Riverpod · Dio · Sqflite · WorkManager · Connectivity Plus · CachedNetworkImage · Material 3

---

## What it does

| Page | What you can do |
|------|-----------------|
| **Users** | Browse paginated users from `reqres.in`, see how many movies each one has saved, jump into a user's session. |
| **Add user** | Create a new user with a movie‑taste tagline. Saved offline first, synced to `reqres.in` automatically when the network returns. |
| **Movies** | Infinite‑scroll grid of movies fetched from OMDB with cached posters, save/unsave directly from the card, "you've reached the end" footer when exhausted. |
| **Movie detail** | Hero‑animated poster, parallax `SliverAppBar`, full overview from OMDB, live count of how many users saved it, sticky save/unsave button. |
| **Saved movies** | Per‑user grid of saved movies with a gradient header card. |
| **Matches** | Live SQL stream of movies saved by **two or more users**, with a "TOP PICK" badge when every user has saved the same movie. |

Everything is **offline‑first**: the database is the source of truth, the API only
upserts into it. Pull‑to‑refresh and bottom‑of‑list trigger fetches; failures fall back
to the local cache without crashing.

---

## APIs used

| Purpose | Endpoint | Auth |
|---------|----------|------|
| User list | `GET https://reqres.in/api/users?page={n}` | `x-api-key` header |
| Create user | `POST https://reqres.in/api/users` | `x-api-key` header |
| Movie search | `GET https://www.omdbapi.com/?s={term}&page={n}&apikey=...` | API key |
| Movie detail | `GET https://www.omdbapi.com/?i={imdbId}&apikey=...` | API key |

API keys live in `lib/core/env.dart` with sensible `String.fromEnvironment` defaults so
the app works out of the box. To override at build time:

```bash
flutter run --dart-define=REQRES_API_KEY=... --dart-define=OMDB_API_KEY=...
```

---

## Run it

```bash
flutter pub get
flutter run                # or: flutter build apk --debug
```

Requires Flutter 3.10.1+ (see `environment.sdk` in `pubspec.yaml`).

### Verify offline / bad‑network flows

1. Tap the overflow menu on the **Users** page → **Simulate weak network**.  
   Every API call now has a 30% chance to fail, retries with exponential backoff, and
   shows the non‑blocking "Reconnecting…" banner at the top.
2. Turn airplane mode on.  
   - Add a user → it shows up locally with a "sync pending" badge.  
   - Save movies → state is preserved.  
   - Turn the network back on → users sync automatically, badges disappear.

### Background sync

A WorkManager periodic task (`pending-user-sync`) runs hourly when the device is
connected and pushes any users still flagged `pending_sync = 1` to the API. The OS may
delay or coalesce executions — that's expected.

---

## Architecture

A layered, testable structure with one widget / class per file:

```
lib/
├── main.dart                                  # composition root (ProviderScope)
├── core/
│   └── env.dart                               # API keys via dart-define
├── domain/models/                             # plain data models, JSON ↔ DB mapping
│   ├── user_model.dart
│   ├── movie_model.dart
│   └── reqres_models.dart
├── data/
│   ├── local_store.dart                       # sqflite open + migrations (v1 → v3)
│   └── app_repository.dart                    # single source of truth: API + DB + retries
├── app/                                       # app shell + DI + theme
│   ├── app_bootstrap.dart                     # async init (DB → repo)
│   ├── providers.dart                         # Riverpod providers
│   ├── app_state_controller.dart              # ChangeNotifier for users + movies + pagination
│   ├── theme.dart                             # Material 3 light + dark theme builder
│   ├── workmanager_dispatcher.dart            # @pragma('vm:entry-point') background task
│   └── movie_matcher_app.dart                 # MaterialApp, system chrome, WM bootstrap
└── presentation/
    ├── pages/                                 # one screen per file
    │   ├── users_page.dart
    │   ├── add_user_page.dart
    │   ├── movies_page.dart
    │   ├── movie_detail_page.dart
    │   ├── saved_movies_page.dart
    │   └── matches_page.dart
    └── widgets/                               # reusable UI atoms
        ├── reconnecting_banner.dart           # animated, non-blocking retry banner
        ├── staggered_item.dart                # fade + slide entrance animation
        ├── movie_poster.dart                  # CachedNetworkImage + shimmer
        ├── save_count_chip.dart               # animated count pill
        ├── bookmark_button.dart               # animated save/unsave
        ├── empty_state.dart                   # icon + title + message + action
        ├── meta_chip.dart
        ├── avatar_bubble.dart
        ├── section_title.dart
        ├── shimmers.dart                      # list + grid skeletons
        ├── user_card.dart
        └── movie_card.dart
```

### Why this shape

- **Domain → Data → Presentation** so the UI never talks to HTTP or SQL directly.
- `AppRepository` owns the **`_safeRequest`** helper that wraps every API call with up‑to‑3 retries + exponential backoff, weak‑network simulation, and a `reconnecting` stream the banner subscribes to.
- `AppStateController` is a small `ChangeNotifier` that handles user pagination, movie pagination (with a `hasMoreMovies` exhaustion flag), and toggling saves.
- The Matches page reads from a `dataChanged` `Stream<int>` so it rebuilds whenever any save/unsave happens — the **live data** requirement.
- Reusable presentation atoms keep page files short and consistent (~150 lines each).

### Data flow (saving a movie)

```
MoviesPage tap → AppStateController.toggleSave
  → AppRepository.toggleSavedMovie
      → upsert movie row
      → insert/delete saved_movies row
      → dataChanged.add(now)
  → MatchesPage StreamBuilder rebuilds → matches() SQL with HAVING COUNT >= 2
```

### Pagination strategy (OMDB)

OMDB requires a search term, so a logical page is mapped to a `(searchTerm, omdbPage)`
pair across a small ring of generic terms (`movie`, `love`, `star`, …). Each fetched
page is upserted into the local `movies` table and returned in API order so the grid
shows new content immediately even before SQL has indexed it. When OMDB yields only
duplicates or an empty page, `hasMoreMovies` flips to `false` and the bottom loader
disappears in favour of a "You've reached the end" footer.

### Bad‑network handling

- All HTTP goes through `_safeRequest` (Dio + retry loop).
- On the first retry, the controller emits `reconnecting = true`; the **`ReconnectingBanner`** at the top fades in.
- Retries use exponential backoff (400ms, 800ms, 1.6s).
- On final failure, every read falls back to local data; every write stays flagged `pending_sync = 1` and is retried by WorkManager + the connectivity listener.
- The user can flip a "Simulate weak network" toggle from the Users page to verify these flows manually.

---

## Technical checklist (assignment rubric)

| Requirement | Implementation |
|-------------|----------------|
| Language | Dart |
| State management | Riverpod (`Provider`, `ChangeNotifierProvider`) |
| Dependency injection | Riverpod `ProviderScope` overrides in `main.dart` |
| Network calls | Dio + custom `_safeRequest` retry wrapper |
| Local database | Sqflite with versioned migrations (v3) |
| Background sync | WorkManager periodic task (`pending-user-sync`) |
| Pagination | Infinite scroll on users and movies |
| Live data (Matches) | `StreamBuilder` over `repo.dataChanged` + SQL `HAVING >= 2` |
| Image loading | `CachedNetworkImage` with shimmer placeholder + fade‑in |
| UI design system | Material 3, light + dark themes |

---

## Build verification

```bash
flutter analyze --no-pub        # → No issues found!
flutter build apk --debug       # → Built build/app/outputs/flutter-apk/app-debug.apk
```
#   F l u t t e r _ P l a t f o r m _ C o m m o n s 
 
 
