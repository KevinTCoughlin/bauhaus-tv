# CLAUDE.md

## Build

```bash
# Build (tvOS Simulator)
xcodebuild build \
  -project Bauhaus.xcodeproj \
  -scheme Bauhaus \
  -sdk appletvsimulator \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Test
xcodebuild test \
  -project Bauhaus.xcodeproj \
  -scheme Bauhaus \
  -sdk appletvsimulator \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Architecture

MVVM with SwiftUI and `@Observable` (Swift Observation framework, tvOS 17+). Zero third-party dependencies.

- **Caching** — 50 MB `URLCache` shared between `BauhausAPI` (URLSession) and `AsyncImage` (URLSession.shared). `BauhausAPI.init()` sets `URLCache.shared` so both use the same cache. Respects CDN `Cache-Control: max-age=300` on today's endpoints.
- **Skip logic** — `ArtworkViewModel.load()` checks `UserDefaults` key `lastUpdatedDate` against today before fetching. Avoids redundant CDN requests across launches.
- **Image format** — `?format=jpeg` on all image URLs. tvOS lacks native AVIF; JPEG is universally safe.
- **Top Shelf** — `TVTopShelfContentProvider` in `BauhausTopShelf` extension. Registers `bauhaus://` URL scheme in the app for `displayAction` to open the app from the home screen shelf.
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
| `GET /api/today?format=jpeg` | Daily stylized image |
| `GET /api/today.json` | Metadata (snake_case JSON) |

## Key Files

| File | Purpose |
|---|---|
| `Bauhaus/Services/BauhausAPI.swift` | Networking singleton, URLCache config |
| `Bauhaus/ViewModels/ArtworkViewModel.swift` | `@Observable` state, skip-today logic |
| `Bauhaus/ContentView.swift` | ZStack: AsyncImage + gradient + metadata overlay |
| `BauhausTopShelf/TopShelfProvider.swift` | TVTopShelfInsetContent with today's image |
| `BauhausTests/ArtworkMetadataTests.swift` | JSON decoding + formattedDate tests |
| `BauhausTests/ArtworkViewModelTests.swift` | Initial state + imageURL tests |
