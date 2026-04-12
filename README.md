# Bauhaus for Apple TV, iOS & macOS

A tvOS, iOS, and macOS app that displays the daily Bauhaus stylized artwork full-screen. Powered by the [bauhaus](https://github.com/kevintcoughlin/bauhaus) backend — a zero-cost daily art generation pipeline using AdaIN neural style transfer.

## Features

- Full-screen daily artwork (landscape photo + style transfer)
- **History navigation** — swipe (iOS/macOS) or d-pad (tvOS) to browse past days
- Metadata overlay: title, style artist, date (toggle with tap or Play/Pause)
- **Set as wallpaper** — long press or right-click on macOS to set the current artwork as your desktop wallpaper
- Top Shelf Extension: last 7 days shown on the Apple TV home screen
- macOS Screen Saver: daily artwork as your screen saver
- 50 MB disk cache via URLCache — one CDN request per day
- Background refresh (tvOS): pre-fetches metadata every 6 hours

## Platforms

| Target | Scheme | Platforms |
|--------|--------|-----------|
| Bauhaus | `Bauhaus` | tvOS 17+ |
| BauhausIOS | `BauhausIOS` | iOS 17+, Mac Catalyst |
| BauhausTopShelf | `BauhausTopShelf` | tvOS 17+ (Top Shelf extension) |
| BauhausScreenSaver | `BauhausScreenSaver` | macOS 14+ |

## Requirements

- Xcode 26+
- tvOS 17.0+ / iOS 17.0+ / macOS 14.0+ deployment targets
- Apple Developer account (for signing)

## Getting Started

```bash
open Bauhaus.xcodeproj
```

Set your Team in the Signing & Capabilities tab for both targets (`Bauhaus` and `BauhausTopShelf`), then build and run on the Apple TV simulator or device.

### Build from command line

```bash
# tvOS Simulator
xcodebuild build -project Bauhaus.xcodeproj -scheme Bauhaus \
  -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# iOS / Mac Catalyst
xcodebuild build -project Bauhaus.xcodeproj -scheme BauhausIOS \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run tests
xcodebuild test -project Bauhaus.xcodeproj -scheme Bauhaus \
  -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  -enableCodeCoverage YES \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Lint
swiftlint lint
```

## Architecture

MVVM with SwiftUI and `@Observable`. Zero third-party dependencies.

```
Bauhaus/                          # tvOS app
├── BauhausApp.swift              # @main, URLCache, background refresh
├── ContentView.swift             # Full-screen ZStack: image + gradient + metadata
├── Models/
│   └── ArtworkMetadata.swift     # Codable struct (title, artist, date, style)
├── Services/
│   └── BauhausAPI.swift          # URLSession + URLCache, /api/today.json
├── ViewModels/
│   └── ArtworkViewModel.swift    # @Observable, history nav, task cancellation
└── Views/
    └── FadeInAsyncImage.swift    # Opacity-fade AsyncImage wrapper

BauhausIOS/                       # iOS / Mac Catalyst app
├── BauhausIOSApp.swift           # @main entry
├── ContentView.swift             # Swipe nav + wallpaper gesture (macOS)
└── WallpaperService.swift        # macOS wallpaper via AppleScript (Catalyst)

BauhausTopShelf/                  # tvOS Top Shelf extension
└── TopShelfProvider.swift        # Last 7 days as sectioned content

BauhausScreenSaver/               # macOS screen saver
└── BauhausScreenSaverView.swift  # NSImageView + daily refresh

BauhausIntents/                   # App Intents / Shortcuts
└── ArtworkAppIntents.swift       # "Show Today's Artwork" shortcut
```

## API

Consumes the public Cloudflare Workers API:

| Endpoint | Usage |
|---|---|
| `/api/today?format=jpeg` | Daily stylized image |
| `/api/today.json` | Metadata (title, artist, style info, date) |
| `/api/YYYY-MM-DD?format=jpeg` | Past date image (1-year immutable cache) |
| `/api/YYYY-MM-DD.json` | Past date metadata |

## Bundle IDs

| Target | Bundle ID |
|---|---|
| Bauhaus (app) | `com.cascadiacollections.bauhaus-tv` |
| BauhausTopShelf (extension) | `com.cascadiacollections.bauhaus-tv.topshelf` |
| BauhausIOS (app) | `com.cascadiacollections.bauhaus-ios` |
