# PixelPen — Developer Guide

PixelPen is a free, open-source pixel-art editor and animation tool built with the
Godot Engine. It runs both as a Godot editor plugin and as a standalone
application. The interface and application logic are written in GDScript;
performance-critical image operations are implemented in C++ as a GDExtension.

This document describes how to set up a development environment, build the native
extension, and work within the codebase. For end-user instructions see
[`README.md`](README.md).

---

## Tech stack

| Component            | Version / Tool                                    |
| -------------------- | ------------------------------------------------- |
| Engine               | Godot **4.7.x** (project targets `4.7`)           |
| Native bindings      | [`godot-cpp`](https://github.com/godotengine/godot-cpp) — pinned at `godot-4.5-stable` (submodule) |
| Extension minimum    | Godot `4.5` (`compatibility_minimum` in the `.gdextension`) |
| Build system         | [SCons](https://scons.org/) 4.x + Python 3.x      |
| Language             | GDScript (UI/logic) and C++17 (GDExtension)       |

> The extension is compiled against the godot-cpp `4.5` API and relies on
> GDExtension forward-compatibility to run inside Godot 4.7. An extension built
> against an older API works in newer minor versions, but not the reverse.

---

## Repository layout

```
pixelpen/
├── project/                     # The Godot project (open this in the editor)
│   ├── project.godot
│   └── addons/net.yarvis.pixel_pen/
│       ├── plugin.cfg           # Editor-plugin manifest
│       ├── pixelpen_plugin.gd   # EditorPlugin entry point
│       ├── pixelpen.gdextension # GDExtension manifest (points at bin/)
│       ├── bin/                 # Compiled native libraries (build output)
│       ├── classes/             # Core GDScript classes (data model, state)
│       ├── editor/              # Editor UI: main window, dialogs, canvas, tools
│       ├── ui/                  # Reusable, theme-driven UI components
│       ├── resources/           # Theme, shaders, icons, fonts
│       └── thirdparty/          # Vendored third-party GDScript
├── src/                         # C++ GDExtension sources
├── godot-cpp/                   # godot-cpp bindings (git submodule)
├── tools/                       # Build helper scripts
├── SConstruct                   # Root build script
└── .github/workflows/           # CI: per-platform + release builds
```

### Native sources (`src/`)

| File                 | Purpose                                                    |
| -------------------- | ---------------------------------------------------------- |
| `register_types.cpp` | Registers `PixelPenCPP` and `PixelPenImage` with the engine |
| `PixelPenCPP.*`      | Batch pixel/colormap operations, palette import, quantization |
| `PixelPenImage.*`    | Indexed-image helpers used by the canvas                   |

---

## Prerequisites

- **Godot 4.7.x** editor (standard build).
- **Python 3.x** and **SCons 4.x** — `pip install scons`.
- A C++ toolchain for your target platform:
  - **Windows** — MSVC (Visual Studio Build Tools). The build uses MSVC by default.
  - **Linux** — `build-essential`, `pkg-config`.
  - **macOS** — Xcode command-line tools.
  - **Android** — JDK 17 and the Android SDK/NDK (`r28b`).
  - **Web** — Emscripten `3.1.62`.

---

## Getting the source

Clone with submodules so the bindings are present:

```sh
git clone --recurse-submodules https://github.com/pixelpen-dev/pixelpen.git
cd pixelpen
```

If you already cloned without submodules:

```sh
git submodule update --init --recursive
```

---

## Building the GDExtension

The root `SConstruct` builds the godot-cpp bindings and the PixelPen library in a
single invocation and writes the result to
`project/addons/net.yarvis.pixel_pen/bin/`.

Build the debug and release libraries for your platform, for example on Windows:

```sh
scons platform=windows target=template_debug   arch=x86_64
scons platform=windows target=template_release arch=x86_64
```

Common parameters:

| Parameter   | Values                                                       |
| ----------- | ------------------------------------------------------------ |
| `platform`  | `windows`, `linux`, `macos`, `android`, `web`                |
| `target`    | `template_debug`, `template_release`                         |
| `arch`      | `x86_64`, `x86_32`, `arm64`, `arm32`, `wasm32`, `universal`  |

### Batch builds

`tools/build.sh` compiles debug + release for a platform (or `all`):

```sh
tools/build.sh windows      # windows | linux | macos | web | android | all
```

After a successful build, the manifest
`project/addons/net.yarvis.pixel_pen/pixelpen.gdextension` resolves the freshly
built library and the extension loads when the project is opened.

> Only the platform/arch you build is refreshed. A release must ship libraries for
> every declared platform in the manifest — CI (below) produces the full set.

---

## Running

PixelPen can be run two ways from the same project:

- **Standalone application** — open `project/` in Godot and run the main scene
  `res://addons/net.yarvis.pixel_pen/editor/editor_main_ui.tscn` (already set as
  `run/main_scene`). Export it like any Godot project to ship a desktop or mobile app.
- **Editor plugin** — enable the plugin under
  *Project → Project Settings → Plugins*. PixelPen opens in its own window from the
  editor toolbar. Disable single-window mode so it detaches cleanly.

---

## Architecture overview

### Application state

`PixelPen` (`classes/pixelpen.gd`) is a lightweight holder exposing a single static
`PixelPenState` instance (`PixelPen.state`). State carries the current project,
user configuration, and the signals that drive the UI (`project_file_changed`,
`layer_items_changed`, `ui_scale_changed`, and so on). Components subscribe to these
signals rather than polling.

### Data model

- `PixelPenProject` — the document: canvas size, frames, palette, animation
  timeline, and view flags. Serialized to `.pxpen` (a ZIP archive: `config.json`
  plus per-layer binary colormaps) via `ProjectPacker`.
- `Frame` / `IndexedColorImage` — a frame owns layers; each layer stores an indexed
  colormap referencing the project palette.
- `UndoRedoManager` — per-project undo history.

> Resource duplication note: `Resource.duplicate()` does **not** deep-copy nested
> subresources or typed arrays. Helpers such as `Frame.get_duplicate()` explicitly
> re-duplicate their layer arrays — preserve that pattern when adding new resources.

### User configuration

`UserConfig` (`classes/user_config.gd`) is a typed `Resource` saved to
`user://pixelpen_user_config.res`. It holds preferences, the accent color, recent
projects, and the persisted dock layout. `resolve_null()` back-fills newly added
fields, so adding an `@export var` is backward-compatible with existing saves.

### Docking & layout

The editor docks are arranged by a custom split system in `ui/layout_split/`
(`LayoutSplit`, `DataBranch`, `Branch`). The layout is persisted per orientation in
`UserConfig`; see `ThemeConfig.get_default_layout()` and the save/restore logic in
`editor/editor_main_ui/editor_main_ui.gd`. Bump `ThemeConfig.LAYOUT_VERSION` when the
default dock structure changes so stale saved layouts fall back to the default.

---

## UI components & theming

The effective theme is the combination of two sources:

1. **`resources/default_theme.tres`** — all static styling (styleboxes, fonts,
   spacing, colors), exposed through named **theme type variations**
   (`AccentButton`, `IconButton`, `WindowPanel`, `ToggleLeft/Mid/Right`,
   `PanelEdit`, `PanelFloat`, …).
2. **`UserConfig`** — the dynamic, per-user values, chiefly `accent_color`.

Follow these conventions when building UI:

- **Style via `theme_type_variation`, not script.** Do not construct
  `StyleBoxFlat` or call `add_theme_*_override` for visual styling; add a variation
  to `default_theme.tres` and reference it. Read values with
  `get_theme_color(...)` / `get_theme_stylebox(...)` when a component needs them at
  runtime.
- **Static styling lives in the theme; the accent lives in `UserConfig`.** The
  accent color is read from `PixelPen.state.userconfig.accent_color`, never
  hardcoded. Do not duplicate theme values as script constants.
- **Reusable widgets go in `ui/`.** Shared components — `PixelPenAccentButton`,
  `PixelPenIconButton`, `PixelPenToggleButton`, `PixelPenSegmentedPicker`,
  `PixelPenPropertyField`/`PropertySheet`, `PixelPenDialog`,
  `PixelPenViewportToolbar`, `PixelPenPaletteStrip` — are theme-driven and used
  across editor windows.
- **Windows** use the `Window` node with a `WindowPanel`-variation `Panel`
  background for a consistent frame across dialogs.

### High-DPI / UI scale

The window is scaled via `content_scale_factor` (see `ThemeConfig.apply_ui_scale`)
so text and controls stay crisp on large displays. Icons are imported at
`svg/scale = 2.0` and wrapped by `ThemeConfig.ui_icon()` to keep their logical size
while carrying higher-resolution pixels. Keep `svg/scale` in the `.import` files in
sync with `ThemeConfig.ICON_BASE_SCALE`.

---

## Coding conventions

- **GDScript** — tabs for indentation, `snake_case` for functions/variables,
  `PascalCase` for `class_name` types, `SCREAMING_SNAKE_CASE` for constants. Type
  hints on exported and public members. Prefer signal-driven updates over polling.
- **Match the surrounding file** in comment density and idiom.
- **C++** — C++17, follow the existing style in `src/`. Register new classes with
  `GDREGISTER_CLASS` in `register_types.cpp`.
- Keep platform-specific code guarded (`OS.get_name()`, `PixelPen.state.is_mobile()`).

---

## Verifying changes

There is no unit-test harness; changes are validated by exercising the running app.
A fast, repeatable approach for a specific flow is a headless SceneTree script:

```sh
# Windows example — adjust the Godot path for your platform
"…/Godot_v4.7.1-stable_win64_console.exe" --headless --path project --import
"…/Godot_v4.7.1-stable_win64.exe" --path project -s res://your_probe.gd
```

Such a probe can instantiate a scene, drive it for a few frames, and either assert
state or capture `get_viewport().get_texture().get_image()` to a PNG for visual
inspection. Always run a headless `--import` after touching scenes, scripts, or
imported assets to confirm there are no parse or import errors, and remove any
temporary probe scripts before committing.

---

## Continuous integration & releases

`.github/workflows/` contains the build pipeline:

- **`build_all.yml`** — a matrix build of every platform/arch × debug/release,
  invoked on pull requests and via manual dispatch. Artifacts are merged into a
  single downloadable package.
- **`build_release.yml`** — manual dispatch that builds all platforms and drafts a
  GitHub release; it takes a `tag_name` input.
- Per-platform workflows (`build_windows.yml`, etc.) build a single target.

The shared composite action lives in `.github/actions/gdextension/`. It uses MSVC on
Windows, Emscripten `3.1.62` for Web, and NDK `r28b` for Android, and caches the
SCons object directory per platform.

---

## Troubleshooting

- **Extension fails to load** — ensure the submodule is checked out and the library
  for your platform/arch has been built into `bin/`. Check the Godot log for
  `Can't open dynamic library`.
- **Build errors after a `godot-cpp` bump** — clean and rebuild: `scons --clean`,
  and remove stale `.obj`/generated files. The submodule is pinned intentionally —
  confirm binding/API compatibility before changing it.
- **Layout or preferences look wrong after an update** — a saved layout can fall out
  of date; use *View → Reset layout*, or delete
  `user://pixelpen_user_config.res` to reset preferences.

---

## License

PixelPen is released under the MIT License. See [`COPYRIGHT.txt`](COPYRIGHT.txt) and
[`LICENSE.txt`](LICENSE.txt). Contributors are listed in [`AUTHOR.md`](AUTHOR.md).
