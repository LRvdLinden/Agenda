# Build 42 — Apple WeatherKit only

Native code uses `WeatherService.shared.weather(for:including:.daily)` and `com.apple.developer.weatherkit` entitlement. No Open-Meteo API requests remain.

## Required in Apple Developer
1. Select explicit App ID `nl.lrvdlinden.weekdot` (team `EU3UY476T6`).
2. Enable WeatherKit under BOTH **App Capabilities** and **App Services**, save.
3. Regenerate provisioning profiles and build with the new profile using signing in Xcode.
4. Verify app and profile entitlement with `codesign -d --entitlements :- /path/to/Weekdot.app` and `security cms -D -i /path/to/embedded.mobileprovision`.
5. On device reinstall the newly signed app and test Weather in Settings. If error 2 persists with valid entitlements, submit an Apple Developer support request with the exact logs: JWT minting is Apple-side.

Forecast coverage is limited to whatever daily dates WeatherKit returns. The app cannot manufacture a full 14-day forecast if Apple does not offer it.

No full Xcode compilation or device network authentication test was possible here.
