# Weekdot 1.0.0 build 54 — synchronization update

- Keeps EventKit's `EKEventStoreChanged` notification for immediately reported local/provider edits.
- When the app is active, reloads EventKit and Weekdot local calendar snapshots every 45 seconds as a fallback for missed/delayed change notifications.
- Immediately invalidates calendar caches when iCloud key-value notifications announce external setting/style changes.
- Existing editor writes still refresh local calendar and alerts directly; CloudKit synchronization is automatically managed by SwiftData / Apple.
- Does not promise instantaneous Google/Outlook/iCloud server pushes: availability depends on account syncing and OS background execution.
- Does not modify website.
