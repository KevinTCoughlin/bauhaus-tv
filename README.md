# Bauhaus for Apple TV

A tvOS app that displays the daily Bauhaus stylized artwork full-screen. Powered by the [bauhaus](https://github.com/kevintcoughlin/bauhaus) backend — a zero-cost daily art generation pipeline using AdaIN neural style transfer.

## Features

- Full-screen daily artwork (landscape photo + style transfer)
- Metadata overlay: title, style artist, date (toggle with Play/Pause on Siri Remote)
- Top Shelf Extension: today's artwork shown on the Apple TV home screen
- 50 MB disk cache via URLCache — one CDN request per day

## Requirements

- Xcode 15+
- tvOS 17.0+ deployment target
- Apple Developer account (for signing)

## Getting Started

```bash
open Bauhaus.xcodeproj
```

Set your Team in the Signing & Capabilities tab for both targets (`Bauhaus` and `BauhausTopShelf`), then build and run on the Apple TV simulator or device.

## Architecture

```
Bauhaus/
├── BauhausApp.swift          # @main entry
├── ContentView.swift         # Full-screen ZStack: image + gradient + metadata
├── Models/
│   └── ArtworkMetadata.swift # Codable struct (title, artist, date, styleArtist)
├── Services/
│   └── BauhausAPI.swift      # URLSession + URLCache, fetches /api/today.json
└── ViewModels/
    └── ArtworkViewModel.swift # @Observable, skips refresh if already loaded today

BauhausTopShelf/
└── TopShelfProvider.swift    # TVTopShelfContentProvider — shows today's image
```

## API

Consumes the public Cloudflare Workers API:

| Endpoint | Usage |
|---|---|
| `/api/today?format=jpeg` | Daily stylized image |
| `/api/today.json` | Metadata (title, artist, style info, date) |

## App Icon

The `AppIcon.appiconset` is empty — add layered PNG artwork at 400×240 (1x/2x) and 1280×768 (App Store) before release.

## Bundle IDs

| Target | Bundle ID |
|---|---|
| Bauhaus (app) | `com.cascadiacollections.bauhaus-tv` |
| BauhausTopShelf (extension) | `com.cascadiacollections.bauhaus-tv.topshelf` |
