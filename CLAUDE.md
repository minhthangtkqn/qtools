# iOS Code Split Convention

Use simple, feature-based file organization so code stays easy to read and maintain.

- `AppNameApp.swift`
  - App entry point and app-wide lifecycle setup.

- Views by screen or feature:
  - `MainScreenView.swift`
  - `BannerSettingsView.swift`
  - `BabyGrowthView.swift`
  - `BannerDisplayView.swift`
  - `FeatureCard.swift`

- Models and data:
  - `BabyGrowthStat.swift`
  - `BannerConfig.swift`

- View models / state logic (when needed):
  - `BannerViewModel.swift`
  - `BabyGrowthViewModel.swift`

- Utilities and extensions:
  - `Color+Extensions.swift`
  - `View+Modifiers.swift`

Guiding rules:
- One main type or screen per file.
- Keep each file focused: UI in view files, model definitions in model files, business logic in view models.
- Group related files by feature into a common folder if the app grows.
- Prefer clear names that reflect the screen or feature.

Example future structure:

```
App/
  qtoolApp.swift
Views/
  MainScreenView.swift
  BannerSettingsView.swift
  BannerDisplayView.swift
  BabyGrowthView.swift
Components/
  FeatureCard.swift
Models/
  BabyGrowthStat.swift
  BannerConfig.swift
ViewModels/
  BannerViewModel.swift
  BabyGrowthViewModel.swift
Utilities/
  Color+Extensions.swift
  View+Modifiers.swift
```
