#!/usr/bin/env python3
"""Generates Weekdot.xcodeproj (Xcode 16+ project format with synchronized folders).

Every Swift file / asset inside Weekdot/, WeekdotWatch/, WeekdotWidgets/ and Shared/ is picked up
automatically by Xcode, so you only need to re-run this script when targets or build
settings change:   python3 tools/gen_xcodeproj.py
"""
import hashlib, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEAM = "EU3UY476T6"
BUNDLE = "nl.lrvdlinden.weekdot"
VERSION = "1.0.1"
BUILD = "77"


def oid(*parts):
    return hashlib.md5("::".join(parts).encode()).hexdigest()[:24].upper()


def q(v):
    s = str(v)
    if s and all(c.isalnum() or c in "._/" for c in s) and not s[0].isdigit() or s.isdigit():
        return s
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def dict_str(d, indent):
    pad = "\t" * indent
    out = "{\n"
    for k, v in d.items():
        out += pad + "\t" + q(k) + " = " + val_str(v, indent + 1) + ";\n"
    out += pad + "}"
    return out


def val_str(v, indent):
    if isinstance(v, dict):
        return dict_str(v, indent)
    if isinstance(v, list):
        pad = "\t" * indent
        out = "(\n"
        for x in v:
            out += pad + "\t" + val_str(x, indent + 1) + ",\n"
        out += pad + ")"
        return out
    return q(v)


objects = {}


def add(isa, key, **fields):
    i = oid(isa, key)
    d = {"isa": isa}
    d.update(fields)
    objects[i] = d
    return i


# ---------- file references / groups ----------
sync = {name: add("PBXFileSystemSynchronizedRootGroup", name, path=name, sourceTree="<group>")
        for name in ("Weekdot", "WeekdotWatch", "WeekdotWidgets", "WeekdotWatchWidgets", "Shared")}

config_files = ["Weekdot-Info.plist", "WeekdotWatch-Info.plist", "Weekdot-iOS.entitlements", "Weekdot-macOS.entitlements",
                "WeekdotWatch.entitlements", "WeekdotWidgets-Info.plist", "WeekdotWidgets-iOS.entitlements",
                "WeekdotWidgets-macOS.entitlements", "WeekdotWatchWidgets.entitlements"]
config_refs = []
for f in config_files:
    ftype = "text.plist.xml" if f.endswith(".plist") else "text.plist.entitlements"
    config_refs.append(add("PBXFileReference", "cfg" + f, lastKnownFileType=ftype, path=f, sourceTree="<group>"))
config_group = add("PBXGroup", "Config", children=config_refs, path="Config", sourceTree="<group>")

prod_app = add("PBXFileReference", "prod.app", explicitFileType="wrapper.application", includeInIndex="0",
               path="Weekdot.app", sourceTree="BUILT_PRODUCTS_DIR")
prod_watch = add("PBXFileReference", "prod.watch", explicitFileType="wrapper.application", includeInIndex="0",
                 path="WeekdotWatch.app", sourceTree="BUILT_PRODUCTS_DIR")
prod_widget = add("PBXFileReference", "prod.widget", explicitFileType="wrapper.app-extension", includeInIndex="0",
                  path="WeekdotWidgetsExtension.appex", sourceTree="BUILT_PRODUCTS_DIR")
prod_watchwidget = add("PBXFileReference", "prod.watchwidget", explicitFileType="wrapper.app-extension", includeInIndex="0",
                       path="WeekdotWatchWidgetsExtension.appex", sourceTree="BUILT_PRODUCTS_DIR")
products_group = add("PBXGroup", "Products", children=[prod_app, prod_watch, prod_widget, prod_watchwidget], name="Products",
                     sourceTree="<group>")
main_group = add("PBXGroup", "Main", children=[sync["Weekdot"], sync["Shared"], sync["WeekdotWatch"], sync["WeekdotWidgets"],
                                                sync["WeekdotWatchWidgets"], config_group, products_group], sourceTree="<group>")


def phases(key):
    s = add("PBXSourcesBuildPhase", key + "src", buildActionMask="2147483647", files=[],
            runOnlyForDeploymentPostprocessing="0")
    f = add("PBXFrameworksBuildPhase", key + "fw", buildActionMask="2147483647", files=[],
            runOnlyForDeploymentPostprocessing="0")
    r = add("PBXResourcesBuildPhase", key + "res", buildActionMask="2147483647", files=[],
            runOnlyForDeploymentPostprocessing="0")
    return [s, f, r]


def config_list(key, debug, release):
    d = add("XCBuildConfiguration", key + "Debug", buildSettings=debug, name="Debug")
    r = add("XCBuildConfiguration", key + "Release", buildSettings=release, name="Release")
    return add("XCConfigurationList", key + "list", buildConfigurations=[d, r],
               defaultConfigurationIsVisible="0", defaultConfigurationName="Release")


# ---------- build settings ----------
common_project = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "COPY_PHASE_STRIP": "NO",
    "CURRENT_PROJECT_VERSION": BUILD,
    "DEVELOPMENT_TEAM": TEAM,
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MARKETING_VERSION": VERSION,
    "MTL_FAST_MATH": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
}
proj_debug = dict(common_project, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
})
proj_release = dict(common_project, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
})

usage = "Weekdot shows, creates and edits the events in your calendars."

app_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]": "Config/Weekdot-iOS.entitlements",
    "CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]": "Config/Weekdot-iOS.entitlements",
    "CODE_SIGN_ENTITLEMENTS[sdk=macosx*]": "Config/Weekdot-macOS.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "ENABLE_HARDENED_RUNTIME": "YES",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Config/Weekdot-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Weekdot",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity",
    "INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription": usage,
    "INFOPLIST_KEY_NSCalendarsUsageDescription": usage,
    "INFOPLIST_KEY_NSRemindersFullAccessUsageDescription": "Weekdot shows your reminders with a due date in the calendar.",
    "INFOPLIST_KEY_NSRemindersUsageDescription": "Weekdot shows your reminders with a due date in the calendar.",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LD_RUNPATH_SEARCH_PATHS[sdk=iphoneos*]": ["$(inherited)", "@executable_path/Frameworks"],
    "LD_RUNPATH_SEARCH_PATHS[sdk=iphonesimulator*]": ["$(inherited)", "@executable_path/Frameworks"],
    "LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]": ["$(inherited)", "@executable_path/../Frameworks"],
    "MACOSX_DEPLOYMENT_TARGET": "14.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE,
    "PRODUCT_NAME": "Weekdot",
    "SDKROOT": "auto",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator macosx",
    "SUPPORTS_MACCATALYST": "NO",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1,2",
}

watch_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_ENTITLEMENTS": "Config/WeekdotWatch.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "Weekdot",
    "INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription": usage,
    "INFOPLIST_KEY_NSCalendarsUsageDescription": usage,
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown",
    "INFOPLIST_FILE": "Config/WeekdotWatch-Info.plist",
    "INFOPLIST_KEY_WKCompanionAppBundleIdentifier": BUNDLE,
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE + ".watchkitapp",
    "PRODUCT_NAME": "WeekdotWatch",
    "SDKROOT": "watchos",
    "SKIP_INSTALL": "YES",
    "TARGETED_DEVICE_FAMILY": "4",
    "WATCHOS_DEPLOYMENT_TARGET": "10.0",
}

widget_settings = {
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME": "WidgetBackground",
    "CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]": "Config/WeekdotWidgets-iOS.entitlements",
    "CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]": "Config/WeekdotWidgets-iOS.entitlements",
    "CODE_SIGN_ENTITLEMENTS[sdk=macosx*]": "Config/WeekdotWidgets-macOS.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "ENABLE_HARDENED_RUNTIME": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Config/WeekdotWidgets-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Weekdot",
    "INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription": usage,
    "INFOPLIST_KEY_NSCalendarsUsageDescription": usage,
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LD_RUNPATH_SEARCH_PATHS[sdk=iphoneos*]": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
    "LD_RUNPATH_SEARCH_PATHS[sdk=iphonesimulator*]": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
    "LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]": ["$(inherited)", "@executable_path/../Frameworks", "@executable_path/../../../../Frameworks"],
    "MACOSX_DEPLOYMENT_TARGET": "14.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE + ".widgets",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SDKROOT": "auto",
    "SKIP_INSTALL": "YES",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator macosx",
    "SUPPORTS_MACCATALYST": "NO",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1,2",
}

# Apple Watch complications (WidgetKit extension inside the watch app)
watch_widget_settings = {
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME": "WidgetBackground",
    "CODE_SIGN_ENTITLEMENTS": "Config/WeekdotWatchWidgets.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Config/WeekdotWidgets-Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Weekdot",
    "INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription": usage,
    "INFOPLIST_KEY_NSCalendarsUsageDescription": usage,
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE + ".watchkitapp.widgets",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SDKROOT": "watchos",
    "SKIP_INSTALL": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "4",
    "WATCHOS_DEPLOYMENT_TARGET": "10.0",
}

# ---------- targets ----------
watch_widget_target = add("PBXNativeTarget", "watchwidget",
                          buildConfigurationList=config_list("watchwidget", watch_widget_settings, watch_widget_settings),
                          buildPhases=phases("watchwidget"), buildRules=[], dependencies=[],
                          fileSystemSynchronizedGroups=[sync["WeekdotWatchWidgets"], sync["Shared"]],
                          name="WeekdotWatchWidgetsExtension", packageProductDependencies=[],
                          productName="WeekdotWatchWidgetsExtension", productReference=prod_watchwidget,
                          productType="com.apple.product-type.app-extension")

widget_target = add("PBXNativeTarget", "widget",
                    buildConfigurationList=config_list("widget", widget_settings, widget_settings),
                    buildPhases=phases("widget"), buildRules=[], dependencies=[],
                    fileSystemSynchronizedGroups=[sync["WeekdotWidgets"], sync["Shared"]],
                    name="WeekdotWidgetsExtension", packageProductDependencies=[],
                    productName="WeekdotWidgetsExtension", productReference=prod_widget,
                    productType="com.apple.product-type.app-extension")

project_id = oid("PBXProject", "project")
proxy_watchwidget = add("PBXContainerItemProxy", "proxywatchwidget", containerPortal=project_id, proxyType="1",
                        remoteGlobalIDString=watch_widget_target, remoteInfo="WeekdotWatchWidgetsExtension")
WATCH_DEP = add("PBXTargetDependency", "depwatchwidget", target=watch_widget_target, targetProxy=proxy_watchwidget)
bf_watchwidget = add("PBXBuildFile", "bfwatchwidget", fileRef=prod_watchwidget,
                     settings={"ATTRIBUTES": ["RemoveHeadersOnCopy"]})
WATCH_EMBED = add("PBXCopyFilesBuildPhase", "embedwatchext", buildActionMask="2147483647", dstPath="",
                  dstSubfolderSpec="13", files=[bf_watchwidget], name="Embed Foundation Extensions",
                  runOnlyForDeploymentPostprocessing="0")

watch_target = add("PBXNativeTarget", "watch",
                   buildConfigurationList=config_list("watch", watch_settings, watch_settings),
                   buildPhases=phases("watch") + [WATCH_EMBED], buildRules=[], dependencies=[WATCH_DEP],
                   fileSystemSynchronizedGroups=[sync["WeekdotWatch"], sync["Shared"]],
                   name="WeekdotWatch", packageProductDependencies=[],
                   productName="WeekdotWatch", productReference=prod_watch,
                   productType="com.apple.product-type.application")

project_id = oid("PBXProject", "project")

proxy_widget = add("PBXContainerItemProxy", "proxywidget", containerPortal=project_id, proxyType="1",
                   remoteGlobalIDString=widget_target, remoteInfo="WeekdotWidgetsExtension")
proxy_watch = add("PBXContainerItemProxy", "proxywatch", containerPortal=project_id, proxyType="1",
                  remoteGlobalIDString=watch_target, remoteInfo="WeekdotWatch")
dep_widget = add("PBXTargetDependency", "depwidget", target=widget_target, targetProxy=proxy_widget)
dep_watch = add("PBXTargetDependency", "depwatch", platformFilter="ios", target=watch_target,
                targetProxy=proxy_watch)

bf_widget = add("PBXBuildFile", "bfwidget", fileRef=prod_widget,
                settings={"ATTRIBUTES": ["RemoveHeadersOnCopy"]})
bf_watch = add("PBXBuildFile", "bfwatch", fileRef=prod_watch, platformFilter="ios")
embed_ext = add("PBXCopyFilesBuildPhase", "embedext", buildActionMask="2147483647", dstPath="",
                dstSubfolderSpec="13", files=[bf_widget], name="Embed Foundation Extensions",
                runOnlyForDeploymentPostprocessing="0")
embed_watch = add("PBXCopyFilesBuildPhase", "embedwatch", buildActionMask="2147483647",
                  dstPath="$(CONTENTS_FOLDER_PATH)/Watch", dstSubfolderSpec="16", files=[bf_watch],
                  name="Embed Watch Content", runOnlyForDeploymentPostprocessing="0")

app_target = add("PBXNativeTarget", "app",
                 buildConfigurationList=config_list("app", app_settings, app_settings),
                 buildPhases=phases("app") + [embed_ext, embed_watch], buildRules=[],
                 dependencies=[dep_widget, dep_watch],
                 fileSystemSynchronizedGroups=[sync["Weekdot"], sync["Shared"]],
                 name="Weekdot", packageProductDependencies=[], productName="Weekdot",
                 productReference=prod_app, productType="com.apple.product-type.application")

proj_cfg = config_list("project", proj_debug, proj_release)
objects[project_id] = {
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": "1",
        "LastSwiftUpdateCheck": "1600",
        "LastUpgradeCheck": "1600",
        "TargetAttributes": {
            app_target: {"CreatedOnToolsVersion": "16.0"},
            watch_target: {"CreatedOnToolsVersion": "16.0"},
            widget_target: {"CreatedOnToolsVersion": "16.0"},
            watch_widget_target: {"CreatedOnToolsVersion": "16.0"},
        },
    },
    "buildConfigurationList": proj_cfg,
    "developmentRegion": "en",
    "hasScannedForEncodings": "0",
    "knownRegions": ["en", "Base", "ar", "ca", "cs", "da", "de", "el", "es", "fi", "fr", "he", "hi", "hr", "hu",
                     "id", "it", "ja", "ko", "ms", "nb", "nl", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk", "sv",
                     "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant"],
    "mainGroup": main_group,
    "minimizedProjectReferenceProxies": "1",
    "preferredProjectObjectVersion": "77",
    "productRefGroup": products_group,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [app_target, watch_target, widget_target, watch_widget_target],
}


def render():
    out = "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n"
    by_isa = {}
    for k, v in objects.items():
        by_isa.setdefault(v["isa"], []).append((k, v))
    for isa in sorted(by_isa):
        out += f"\n/* Begin {isa} section */\n"
        for k, v in sorted(by_isa[isa]):
            out += "\t\t" + k + " = " + dict_str(v, 2) + ";\n"
        out += f"/* End {isa} section */\n"
    out += "\t};\n\trootObject = " + project_id + ";\n}\n"
    return out


def scheme(name, target_id, product, buildable, launch=True):
    ref = f'''<BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{product}"
               BlueprintName = "{name}"
               ReferencedContainer = "container:Weekdot.xcodeproj">
            </BuildableReference>'''
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            {ref}
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         {ref}
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         {ref}
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''


def main():
    proj = os.path.join(ROOT, "Weekdot.xcodeproj")
    os.makedirs(os.path.join(proj, "xcshareddata", "xcschemes"), exist_ok=True)
    os.makedirs(os.path.join(proj, "project.xcworkspace", "xcshareddata"), exist_ok=True)
    with open(os.path.join(proj, "project.pbxproj"), "w") as f:
        f.write(render())
    with open(os.path.join(proj, "project.xcworkspace", "contents.xcworkspacedata"), "w") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n'
                '   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')
    with open(os.path.join(proj, "xcshareddata", "xcschemes", "Weekdot.xcscheme"), "w") as f:
        f.write(scheme("Weekdot", app_target, "Weekdot.app", True))
    with open(os.path.join(proj, "xcshareddata", "xcschemes", "WeekdotWatch.xcscheme"), "w") as f:
        f.write(scheme("WeekdotWatch", watch_target, "WeekdotWatch.app", True))
    with open(os.path.join(proj, "xcshareddata", "xcschemes", "WeekdotWidgetsExtension.xcscheme"), "w") as f:
        f.write(scheme("WeekdotWidgetsExtension", widget_target, "WeekdotWidgetsExtension.appex", True))
    with open(os.path.join(proj, "xcshareddata", "xcschemes", "WeekdotWatchWidgetsExtension.xcscheme"), "w") as f:
        f.write(scheme("WeekdotWatchWidgetsExtension", watch_widget_target, "WeekdotWatchWidgetsExtension.appex", True))
    print("Weekdot.xcodeproj written")


if __name__ == "__main__":
    main()
