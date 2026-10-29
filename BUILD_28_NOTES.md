# Weekdot 1.0.0 (28) — changes and limitations

- On iPhone and Mac the calendar remains visible with an unselected, floating action bar; **Views** always opens the list of seven calendar views. The Add button remains a menu and Settings is in the top right. The redundant Today/Agenda button was removed from the bottom bar: Today remains available from the date picker above.
- The period/month heading is centered in the navigation bar. Tap it to open the date picker with Today and an explicit confirmation checkmark. Swipe horizontally to move through periods; a long press on the heading also reveals Previous, Today and Next.
- Mini Month now shows a full month grid with individual colored events, closely following the supplied reference, rather than the previous tiny dots + separate agenda. Multiple Weeks retains the compact date/dots layout.
- Persistent local storage no longer silently falls back to a memory-only database. A failed write from the editor now reports failure rather than pretending it succeeded. Further fault injection on a Mac is necessary.
- Build number is 28 for all targets, release version stays 1.0.0.

## Validation

This environment cannot run Apple's `xcodebuild` or a device simulator. Please build the iOS, macOS, Apple Watch and widget targets with Xcode and test the date picker, local saves and all-day dates. This is not a signed binary.
