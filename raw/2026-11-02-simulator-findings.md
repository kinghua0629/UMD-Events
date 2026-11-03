# Simulator findings — 2026-11-02 (Xcode 27.2, iPhone 18 Pro simulator, macOS 27.2)

- `SystemLanguageModel.default.availability` → `.unavailable(.modelNotReady)` ("model still downloading");
  AI summaries could not be exercised in the simulator.
- `LanguageAvailability().status(from:to:)` → `.unsupported` for every pair tried (en/en-US/en-Latn-US →
  zh-Hans, zh-Hans-CN, zh-CN, es, es-ES, de, ja), even though `supportedLanguages` lists 21 languages.
  ⇒ Translation framework doesn't work in the Simulator.
- `xcrun simctl privacy <dev> grant notifications <bundle>` fails: "Failed to create TCC authorization record".
  A pending notification prompt also survives uninstall/reinstall until the simulator is rebooted.
- Simulator.app wasn't open, so no UI tapping/AppleScript; screenshots via `xcrun simctl io <dev> screenshot`.
- Large navigation title disappeared when a segmented Picker was placed in `.safeAreaInset(edge: .top)` of the list.
