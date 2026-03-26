# CLAUDE.md

## Build & Test

```bash
# Build (tvOS Simulator)
xcodebuild build \
  -project Bauhaus.xcodeproj \
  -scheme Bauhaus \
  -sdk appletvsimulator \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Test (builds app + extension + test bundle, then runs tests)
xcodebuild test \
  -project Bauhaus.xcodeproj \
  -scheme Bauhaus \
  -sdk appletvsimulator \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Architecture

MVVM with SwiftUI and `@Observable` (Swift Observation framework, tvOS 17+). Zero third-party dependencies.

- **Caching** — 50 MB `URLCache` shared between `BauhausAPI` (URLSession) and `AsyncImage` (URLSession.shared). `BauhausAPI.init()` sets `URLCache.shared` so both use the same cache. Respects CDN `Cache-Control: max-age=300` on today's endpoints; past dates have 1-year immutable cache (no application-level skip needed).
- **Skip logic** — `ArtworkViewModel.load()` checks `UserDefaults` key `lastUpdatedDate` against today before fetching. Only applies to today; past dates rely on URLCache.
- **Image format** — `?format=jpeg` on all image URLs. tvOS lacks native AVIF; JPEG is universally safe.
- **History navigation** — d-pad left/right on Siri Remote navigates between days. `currentDate` drives all URLs. Past dates use `/api/YYYY-MM-DD` and `/api/YYYY-MM-DD.json` routes.
- **Crossfade** — `FadeInAsyncImage` fades opacity 0→1 over 1.2s on `.onAppear`. Call site uses `.id(viewModel.imageURL)` to force view recreation (and reset opacity) when the URL changes.
- **Background refresh** — `BGAppRefreshTask` registered at launch, scheduled 6h into the future whenever the app backgrounds. Pre-fetches today's metadata so the cache is warm next morning.
- **Top Shelf** — `TVTopShelfContentProvider` shows the last 7 days as `TVTopShelfInsetContent` items. Each item links to `bauhaus://open?date=YYYY-MM-DD`.
- **JSON decoding** — API returns snake_case; decoded with `keyDecodingStrategy = .convertFromSnakeCase`.

## Targets

| Target | Bundle ID | Type |
|---|---|---|
| Bauhaus | `com.cascadiacollections.bauhaus-tv` | tvOS app |
| BauhausTopShelf | `com.cascadiacollections.bauhaus-tv.topshelf` | TV app extension |
| BauhausTests | `com.cascadiacollections.bauhaus-tv.tests` | Hosted unit test bundle |

## API

Backend: [bauhaus](https://github.com/KevinTCoughlin/bauhaus) — Python pipeline on GitHub Actions → Cloudflare R2 + Workers.

| Endpoint | Purpose |
|---|---|
| `GET /api/today?format=jpeg` | Today's image |
| `GET /api/today.json` | Today's metadata |
| `GET /api/YYYY-MM-DD?format=jpeg` | Past date image (1-year immutable cache) |
| `GET /api/YYYY-MM-DD.json` | Past date metadata |

## Key Files

| File | Purpose |
|---|---|
| `Bauhaus/BauhausApp.swift` | Entry point, URLCache config, BGTaskScheduler registration |
| `Bauhaus/ContentView.swift` | ZStack: image + gradient + metadata + d-pad navigation |
| `Bauhaus/Views/FadeInAsyncImage.swift` | Opacity-fade wrapper around AsyncImage |
| `Bauhaus/Services/BauhausAPI.swift` | Networking, URL builders for today + past dates |
| `Bauhaus/ViewModels/ArtworkViewModel.swift` | `@Observable` state, history navigation, skip logic |
| `BauhausTopShelf/TopShelfProvider.swift` | Last 7 days as TVTopShelfInsetContent |
| `BauhausTests/BauhausAPITests.swift` | URL generation for today + specific past dates |
| `BauhausTests/HistoryNavigationTests.swift` | goToPreviousDay / goToNextDay / boundary guards |

## Remote Controls

| Input | Action |
|---|---|
| Play/Pause | Toggle metadata overlay |
| D-pad left | Go to previous day |
| D-pad right | Go to next day (blocked if already on today) |
