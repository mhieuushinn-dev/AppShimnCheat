# Shinn Cheat iOS

SwiftUI iOS app using the requested monochrome black/white glass UI.

## Project structure

```text
.
├── .github/
│   └── workflows/
│       └── build.yml
├── ShinnCheat/
│   ├── ShinnCheatApp.swift
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── Glass.swift
│   ├── Models.swift
│   └── SecondaryViews.swift
└── ShinnCheat.xcodeproj/
    ├── project.pbxproj
    └── xcshareddata/
        └── xcschemes/
            └── ShinnCheat.xcscheme
```

## Build

Open `ShinnCheat.xcodeproj` in Xcode.

The GitHub Actions workflow builds an **unsigned** IPA. An unsigned IPA is an archive artifact and is not directly installable on a normal iPhone until it is signed with an appropriate Apple certificate/provisioning profile.

## Current app behavior

- Member-oriented free UI.
- No Device UID/key/license flow.
- Owner/Admin/Support information screens.
- No bottom tab bar.
- Black/white glass-style interface.
- Settings and About screens.
