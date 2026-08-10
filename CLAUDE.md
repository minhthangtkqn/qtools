# CLAUDE.md — qtools

## Project overview

Native iOS app (SwiftUI, Swift 5.0, iOS 18.5) bundling independent utility tools.  
No external dependencies — pure Apple SDK + URLSession.

## Adding a new feature

Follow these four steps in order.

### Step 1 — Ask for the feature title if not given

If the prompt does not include a feature title, ask:

> "What should the feature card be titled on the home screen?"

The title is used for both the card label and the `.navigationTitle` on the feature view.

---

### Step 2 — Add a case to the `Feature` enum

File: `qtool/ContentView.swift`

```swift
enum Feature: String, Hashable {
    case banner
    case weekGrowth
    case qaChat
    case myNewFeature   // ← add here, camelCase
}
```

---

### Step 3 — Wire up the home screen

In `MainScreenView` (`qtool/ContentView.swift`), add two things:

**a) A `NavigationLink` card in the grid:**

```swift
NavigationLink(value: Feature.myNewFeature) {
    FeatureCard(title: "My New Feature")
}
```

**b) A `case` in the `navigationDestination` switch:**

```swift
case .myNewFeature:
    MyNewFeatureView()
```

---

### Step 4 — Create the feature view

Create a new file `qtool/Views/MyNewFeature.swift`.

Minimum shell — navigation bar with back button and title are provided automatically by `NavigationStack`; just set `.navigationTitle`:

```swift
//
//  MyNewFeature.swift
//  qtool
//

import SwiftUI

struct MyNewFeatureView: View {
    var body: some View {
        // feature content here
        Text("Hello from My New Feature")
            .navigationTitle("My New Feature")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MyNewFeatureView()
    }
}
```

> **Back button** — no extra code needed. Because all feature views are pushed inside the root `NavigationStack` in `ContentView`, SwiftUI automatically renders a back button that returns to the home screen.

---

## Existing features at a glance

| `Feature` case | Card title | View file | Notes |
|---|---|---|---|
| `.banner` | Banner | `Views/Banner.swift` | Forces landscape orientation for display |
| `.weekGrowth` | Baby Growth | `Views/BabyGrowth.swift` | Hardcoded WHO z-score tables |
| `.qaChat` | AI Chat | `Views/QAChat.swift` | Gemini REST API, multi-modal input |

## Key conventions

- **API keys** — stored in `Secrets.swift` (gitignored). Access via `Secrets.geminiAPIKey`.
- **Orientation** — portrait locked globally in `AppDelegate`. Only the Banner display view overrides this.
- **Shared state** — `ChatSession` is an `@EnvironmentObject` injected at the root. Pass it down only if the new feature needs persistent chat history; otherwise use local `@State`.
- **File header** — match the existing comment block style (`// Created by Hoang Minh Thang on …`).
