Weekdot 1.0.0 (36) — Dutch localization and weather reliability

- Remove weather from the calendar-subscription catalog, including all country pages. Weather belongs in Settings and the calendar itself.
- Localize new weather error/status/city field labels and additional missing Dutch UI strings, including Circulus and notification settings.
- Force calendar weather refresh after a city change. Apple WeatherKit remains preferred, Open-Meteo fallback and a fallback geocoding endpoint remain available.
- Show weather at the top of each week-day cell, outside the scrollable event list, so appointments cannot push it out of view.
- Provide clear localized weather errors instead of raw decoder errors.
- Keep website unchanged.

Validation: Swift syntax-only parse, localization JSON/catalog validation, ZIP checksum test. Full Xcode compile and on-device WeatherKit must still be verified on a Mac with the capability enabled. Availability and permissions can still affect live forecasts.
