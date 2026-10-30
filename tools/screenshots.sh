#!/bin/bash
# Makes App Store / website screenshots of Weekdot in the iOS, iPadOS and watchOS simulators (and the Mac app)
# using the app's screenshot mode (launch argument -WDScreenshot <scene>, sample data, no permission prompts).
# Output: shots/<lang>/<device>/<scene>.png      Usage: tools/screenshots.sh "en nl" "week month day event discover sports list"
set -uo pipefail
LANGS=${1:-"en nl"}
SCENES=${2:-"week month day event list discover sports"}
OUT=${OUT:-shots}
PLATFORMS=${PLATFORMS:-"ios watch mac"}   # e.g. PLATFORMS=watch to only redo the watch shots
has() { [[ " $PLATFORMS " == *" $1 "* ]]; }
BUNDLE=nl.lrvdlinden.weekdot
mkdir -p "$OUT"

pick() { xcrun simctl list devicetypes | sed -E 's/ \(com\.apple.*//' | grep -E "$1" | sort -V | tail -1; }
runtime() { xcrun simctl list runtimes | grep -oE "com\.apple\.CoreSimulator\.SimRuntime\.$1-[0-9-]+" | sort -V | tail -1; }

IPHONE=$(pick '^iPhone [0-9]+ Pro Max$'); IPAD=$(pick '^iPad Pro 13-inch \(M[0-9]+\)$'); WATCH=$(pick '^Apple Watch Ultra [0-9]+ \(49mm\)$')
[ -z "$WATCH" ] && WATCH=$(pick '^Apple Watch Series [0-9]+ \(46mm\)$')
IOS_RT=$(runtime iOS); WOS_RT=$(runtime watchOS)
echo "iPhone: $IPHONE | iPad: $IPAD | Watch: $WATCH | $IOS_RT | $WOS_RT"

PHONE_ID=$(xcrun simctl create "Shot iPhone" "$IPHONE" "$IOS_RT")
PAD_ID=$(xcrun simctl create "Shot iPad" "$IPAD" "$IOS_RT")
WATCH_ID=$(xcrun simctl create "Shot Watch" "$WATCH" "$WOS_RT")

if has ios; then
echo "::group::Build iOS app"
xcodebuild -project Weekdot.xcodeproj -scheme Weekdot -destination "id=$PHONE_ID" -derivedDataPath dd \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build -quiet || exit 1
echo "::endgroup::"
APP=$(find dd/Build/Products -maxdepth 2 -name Weekdot.app -path '*iphonesimulator*' | head -1)

shoot_ios() { # device-id device-name
  local dev=$1 name=$2
  xcrun simctl boot "$dev"; xcrun simctl bootstatus "$dev" -b >/dev/null
  xcrun simctl status_bar "$dev" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
  xcrun simctl ui "$dev" appearance light || true
  xcrun simctl install "$dev" "$APP"
  for lang in $LANGS; do
    case $lang in nl) loc=nl_NL;; de) loc=de_DE;; fr) loc=fr_FR;; es) loc=es_ES;; it) loc=it_IT;; *) loc=en_GB;; esac
    mkdir -p "$OUT/$lang/$name"
    for scene in $SCENES; do
      xcrun simctl terminate "$dev" $BUNDLE 2>/dev/null
      xcrun simctl launch "$dev" $BUNDLE -WDScreenshot "$scene" -AppleLanguages "($lang)" -AppleLocale "$loc" >/dev/null
      case $scene in sports|discover) sleep 16;; *) sleep 7;; esac
      xcrun simctl io "$dev" screenshot "$OUT/$lang/$name/$scene.png" >/dev/null && echo "✓ $lang $name $scene"
    done
    # one dark-mode week shot
    xcrun simctl ui "$dev" appearance dark || true
    xcrun simctl terminate "$dev" $BUNDLE 2>/dev/null
    xcrun simctl launch "$dev" $BUNDLE -WDScreenshot week -AppleLanguages "($lang)" -AppleLocale "$loc" >/dev/null
    sleep 7; xcrun simctl io "$dev" screenshot "$OUT/$lang/$name/week-dark.png" >/dev/null
    xcrun simctl ui "$dev" appearance light || true
  done
  xcrun simctl shutdown "$dev"
}
shoot_ios "$PHONE_ID" iphone
shoot_ios "$PAD_ID" ipad
fi

if has watch; then
echo "::group::Build watch app"
xcodebuild -project Weekdot.xcodeproj -scheme WeekdotWatch -destination "id=$WATCH_ID" -derivedDataPath dd \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build -quiet
echo "::endgroup::"
WAPP=$(find dd/Build/Products -maxdepth 2 -name WeekdotWatch.app -path '*watchsimulator*' | head -1)
if [ -n "$WAPP" ]; then
  xcrun simctl boot "$WATCH_ID"; xcrun simctl bootstatus "$WATCH_ID" -b >/dev/null
  xcrun simctl install "$WATCH_ID" "$WAPP"
  for lang in $LANGS; do
    case $lang in nl) loc=nl_NL;; *) loc=en_GB;; esac
    mkdir -p "$OUT/$lang/watch"
    for scene in day week event; do
      xcrun simctl terminate "$WATCH_ID" $BUNDLE.watchkitapp 2>/dev/null
      xcrun simctl launch "$WATCH_ID" $BUNDLE.watchkitapp -WDScreenshot $scene -AppleLanguages "($lang)" -AppleLocale "$loc" >/dev/null
      sleep 9; xcrun simctl io "$WATCH_ID" screenshot "$OUT/$lang/watch/$scene.png" >/dev/null && echo "✓ $lang watch $scene"
    done
  done
  xcrun simctl shutdown "$WATCH_ID"
fi
fi

if has mac; then
echo "::group::Build Mac app"
xcodebuild -project Weekdot.xcodeproj -scheme Weekdot -destination "platform=macOS" -derivedDataPath ddmac \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build -quiet
echo "::endgroup::"
MAPP=$(find ddmac/Build/Products -maxdepth 2 -name Weekdot.app | head -1)
if [ -n "$MAPP" ]; then
  cat > winid.swift <<'SW'
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list where (w[kCGWindowOwnerName as String] as? String) == "Weekdot" && (w[kCGWindowLayer as String] as? Int) == 0 {
  print(w[kCGWindowNumber as String] as? Int ?? 0); break
}
SW
  for lang in $LANGS; do
    case $lang in nl) loc=nl_NL;; *) loc=en_GB;; esac
    mkdir -p "$OUT/$lang/mac"
    for scene in week day month list sports; do
      pkill -x Weekdot 2>/dev/null; sleep 1
      "$MAPP/Contents/MacOS/Weekdot" -WDScreenshot "$scene" -AppleLanguages "($lang)" -AppleLocale "$loc" >/dev/null 2>&1 &
      case $scene in sports|discover) sleep 18;; *) sleep 9;; esac
      WID=$(swift winid.swift 2>/dev/null | head -1)
      if [ -n "$WID" ] && [ "$WID" != "0" ]; then screencapture -x -o -l"$WID" "$OUT/$lang/mac/$scene.png" && echo "✓ $lang mac $scene"
      else screencapture -x "$OUT/$lang/mac/$scene-screen.png"; fi
    done
    pkill -x Weekdot 2>/dev/null
  done
fi
fi
find "$OUT" -name '*.png' | sort
