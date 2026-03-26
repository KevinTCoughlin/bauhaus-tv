# Contributing

Contributions welcome. Please open an issue before submitting a PR for non-trivial changes.

## Getting Started

1. Fork and clone the repo
2. Open `Bauhaus.xcodeproj` in Xcode 15+
3. Set your Team in **Signing & Capabilities** for both `Bauhaus` and `BauhausTopShelf` targets
4. Build and run on the Apple TV simulator

## Running Tests

```bash
xcodebuild test \
  -project Bauhaus.xcodeproj \
  -scheme Bauhaus \
  -sdk appletvsimulator \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Conventions

- SwiftUI + `@Observable` — no UIKit, no `ObservableObject`/`@Published`
- Zero third-party dependencies — use URLSession, AsyncImage, and system frameworks only
- Add unit tests for any new model or service logic in `BauhausTests/`
- Match the existing code style (no force-unwraps in new code, prefer `async/await`)
