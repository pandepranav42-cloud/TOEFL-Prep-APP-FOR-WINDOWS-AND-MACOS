# What changed vs the previous zip

## This pass (iPad safe area + Stage Manager)

- **iPad safe area is now handled correctly.** The whole root was calling
  `.ignoresSafeArea()`, which meant content rendered under the iPad
  status bar. Now only the aurora wallpaper and the falling petals ignore
  safe area (they should reach every edge); the sidebar and content pane
  stay inside the safe area, so nothing collides with the status bar or
  home indicator.

- **The 16 px iPad top spacer is gone.** It was there to compensate for
  the status bar, but the safe area handles that automatically. Sidebar
  now starts flush against the safe-area top on iPad and keeps its 44 px
  traffic-light clearance on macOS.

- **Stage Manager resize works.** Added
  `UIApplicationSupportsMultipleScenes = YES` and
  `UIRequiresFullScreen = NO` to the Info.plist keys, so on iPad Pro you
  can resize the app in Stage Manager or run it in split-screen with
  another app. iPad still won't show macOS-style traffic lights or a
  window frame — iPad apps don't have those — but the resize handle in
  Stage Manager is now available.

## Previous pass (iPad support, GitHub removed, app icon)

- **App icon.** The gradient logo from your HTML favicon is now a real
  `Assets.xcassets/AppIcon` bundle with all six macOS sizes (16, 32, 128,
  256, 512, each in 1× and 2×). There's also a `Logo` imageset containing
  a 1024 × 1024 PNG you can drop into any SwiftUI view with
  `Image("Logo")` — same artwork as the favicon.
- **GitHub button gone.** The Developer card no longer has a GitHub button
  or repo URL. Only *Contact* (opens mail) and *Copy email* remain.
- **App now builds for both macOS and iPad.** The target is a single
  cross-platform SwiftUI app: `SUPPORTED_PLATFORMS = "iphoneos
  iphonesimulator macosx"`, `SDKROOT = auto`, `TARGETED_DEVICE_FAMILY = "1,2"`,
  `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `MACOSX_DEPLOYMENT_TARGET = 14.0`.
  In Xcode's toolbar you can pick **My Mac** or an iPad simulator/device
  and run either.
- **AppKit-only APIs are wrapped or replaced.**
  - `NSOpenPanel` / `NSSavePanel` → `.fileImporter` / `.fileExporter`.
    Same UX on macOS, and the file picker on iPad opens the standard
    Files sheet.
  - `NSPasteboard` → `UIPasteboard` on iPad (`#if os(macOS)` branches).
  - `NSWorkspace.open(url:)` → `@Environment(\.openURL)`.
  - `WindowChrome` (the transparent titlebar helper) is compiled only
    on macOS. iPad has no titlebar.
  - The sidebar's 44 px traffic-light spacer is macOS-only; iPad uses
    a 16 px top gap instead.
  - `.windowStyle(.hiddenTitleBar)`, `.defaultSize(...)`, and
    `SidebarCommands` in the scene are all inside `#if os(macOS)` too.

## Previous pass (Settings width)

- **Settings now fills the window.** The outer VStack had a hard
  `.frame(maxWidth: 860)` cap, so on a normal-sized window the whole page
  hugged the left half and left a big empty gap on the right. Removed —
  the cap is now `.infinity`, so language chips, the import dropzone,
  notifications and the developer card all stretch the full content
  width.
- **Sakura and Sunflower are no longer huge pills.** They were laid out
  in an HStack with a `Spacer`, which meant SwiftUI gave each swatch half
  of the (capped) width. Moved them into the same 8-column `LazyVGrid`
  the core themes use, so they render at the same tile size.

## Previous pass (layout, streak, persistence)

- **The extra dark strip above the sidebar is gone.** The root view was
  padding its glass panel 20 px inside the window, which left a border of
  aurora background showing at the top — that's the strip the traffic lights
  were sitting on. The panel now reaches the window edges the way the
  HTML's `.is-desktop` layout does, and the sidebar leaves a proper 44 px
  clearance so macOS's own traffic lights float over the "Study" section.

- **The streak is now earned, not granted.** Previously `init()` called
  `rollDayIfNeeded()`, which set `currentStreak = 1` the moment you opened
  the app — even before you'd done anything. Now the streak only advances
  when you *actually* do something worth counting: grade a flashcard,
  answer a quiz question, or finish a reading passage. Just opening the
  app doesn't touch it.

- **State no longer clobbers itself during load.** `theme` and `language`
  had `didSet { save() }`. When `load()` assigned `theme = blob.theme`
  mid-load, that fired a save *before* `recentlyShown` and `language`
  had been loaded — writing their defaults back over the file. Now `save()`
  is guarded by an `isLoading` flag, and both settings save explicitly
  from their own tap handlers instead.

- **`recentlyShown` now persists.** `nextTodayWord()` calls `save()`, so
  the row of chips on Today survives a relaunch instead of coming back
  empty every time.

- **Daily Reviews chart shows the current calendar week.** Was a rolling
  7-day window ending today; now it's Sun–Sat (or Mon–Sun, per the user's
  Calendar locale), matching the HTML.

## Previous pass (compile errors)

- **`ReadingView` now imports Combine.** The reader's per-second stopwatch
  used `Timer.publish(...).autoconnect()`. `autoconnect()` lives in Combine,
  not Foundation, so the file didn't compile without an explicit
  `import Combine`.

- **`onChange` uses the modern two-parameter form.** The single-closure
  form was deprecated in macOS 14. The two-parameter form is the modern
  one but requires macOS 14, so —

- **Deployment target is now macOS 14.0.** macOS 14 shipped in September
  2023; every Mac that can run Xcode 15 can run this. Bumping fixed the
  deprecation warning without needing an `@available` dance.

- **`LastUpgradeCheck` bumped to 1600.** Silences Xcode's "Update to
  recommended settings" prompt on modern Xcodes.

## Previous pass (August 9)

- **Library word cards are colour-coded by difficulty again.** The vertical
  accent bar down the left of each card follows the word's own difficulty
  (1..5) instead of its Leitner box. Every fresh word starts in box 1, so
  colouring by box made the whole grid red — now easy words show green,
  hard words show red, and the spread reads at a glance.

- **Developer section is back in Settings.** Sits between Notifications
  and the "reset all progress" footer: monogram, "BUILT BY / Pranav Pande",
  the email in the accent colour, and three buttons — Contact (opens
  Mail), Copy email (uses NSPasteboard, flips to "Copied" for a moment),
  GitHub (opens the repo).

## Previous pass

## Structural

1. **The duplicate UI is gone.** Previously `RootView`, `SettingsView`,
   `AppSection` etc. were declared twice — once in `Views/RootView.swift` and
   once in `App/TOEFLPrepGlassUpgrade.swift`. The two versions competed and
   caused compile errors. There is now one clean sidebar + shell in
   `Views/RootView.swift` and one settings view.

2. **The `App/TOEFLPrepApp .swift` filename had a space.** Renamed to
   `TOEFLPrepApp.swift`.

3. **`App/TOEFLGlassSidebar.swift` was not valid Swift.** Deleted; its
   contents are now correctly assembled inside `RootView.swift`.

## Data / correctness

4. **JSON keys line up with the model.** `vocab.json`, `passages.json` and
   `quotes.json` are unchanged; the models still use `syn`, `ant`, `diff`,
   `answerIndex` — matching what the JSON already contains.

5. **The Leitner box starts at 1.** Previously `WordProgress.box` defaulted
   to 0, so the "box 1" chip in the Library and the box-1 count on the
   Progress screen were both off by one. Corrected.

## Theme

6. **Every colour comes from the HTML stylesheet.** `Theme.swift` is a
   line-for-line port of the CSS custom properties: `--accent`, `--ink`,
   `--panel-solid`, `--aurora-1..4`, `--petal-1..3`, and so on.

7. **The glass effect is themed.** The old code called
   `.background(.ultraThinMaterial)`, which is a fixed system frost that
   ignores the palette. `.glass(theme, style)` in `DesignSystem.swift`
   layers a blur, a themed translucent tint, and a hairline border — so
   Ocean, Ember, Sakura, Sunflower each look distinct.

## Screens — every screen now matches its screenshot

8. **Today** (screenshot 1) — dated eyebrow, "Word of the moment", rotating
   quote card with reload, hero word card with speaker + tags + meaning +
   syn/ant + three buttons; progress ring card with mastered % and mini
   stats; "Recently shown" chip row.

9. **Flashcards** (screenshot 2) — Leitner eyebrow, thin progress bar,
   glass card with the word + 4 orange difficulty dots + "click to reveal",
   four grade buttons (Again / Hard / Good / Easy with box shift
   subtitles), Hear it + Favorite footer.

10. **Quiz** (screenshot 3) — "N words available" eyebrow, question type
    chips (Word → meaning, Meaning → word, Fill in the blank,
    Pronunciation recognition, Typing mode), length chips
    (5 / 10 / 20 questions), Start quiz.

11. **Reading** (screenshot 4) — passages / completed eyebrow, difficulty
    chips (Any level, ★, ★★…), status chips (All / Not read / Completed),
    category dropdown, two-column card grid.

12. **Library** (screenshot 5) — words / mastered / shown eyebrow, search
    bar, difficulty chips, status chips (All / Learned / Not learned /
    ★ Favorites), category dropdown, three-column card grid — every card
    with its coloured Leitner accent bar down the left.

13. **Progress** (screenshot 6) — eight stat cards in a 4-by-2 grid, Daily
    reviews mini chart, Leitner distribution row with per-box counts in
    the coloured pill.

14. **Settings** (screenshot 7) — Language chip row, App colour palette
    (eight core), Special (Sakura, Sunflower), Import and export section
    with dropzone + four buttons, Notifications with a toggle.

## Performance

15. **The wallpaper is one `Canvas` pass** instead of four separately
    animated blurred circles. It reads the palette's own aurora colours.
    Ticks at 20 Hz.

16. **The petals are one `Canvas` pass** with time-based positions,
    replacing twenty separate views each with their own repeating
    animation. Ticks at 30 Hz.

## Language, import, export

17. **Interface language** switches between English, Hindi, Korean,
    Chinese and Japanese. Vocabulary stays English.

18. **Import** accepts a JSON progress export and restores streaks and
    box state. Drop it on the dropzone, or use *Choose file*.

19. **Export** writes JSON progress, CSV vocabulary or JSON passages via
    the standard save panel.

20. **Reset all progress** confirmation is on the Settings page.
