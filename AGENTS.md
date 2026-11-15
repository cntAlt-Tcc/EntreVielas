# AGENTS.md

Repo-specific notes for working on **FiveSync UI** (Roblox UI library, based on Arcane/Compkiller).

## Layout

- `inject.lua` — the library itself (single file, ~10.7k lines). Loaded by users via `loadstring(game:HttpGet(...))()`.
- `example.lua` — the original kitchen-sink example (every element, configs, themes).
- `template.lua` — clean, documented starter for building a panel. Preferred reference for the public API.
- `Script/` — user-provided scripts (not part of the library).

## Branding

The library is **FiveSync UI by EntreViela$ Team**. Logo asset: `rbxassetid://117056629401480`.
Palette is black + neon white. Do not reintroduce the old names (`Compkiller`, `Arcane`) — see git history / PRs #4-#6.

## Toolchain

Luau is not in the repo. Get the binaries once:

```bash
curl -sL -o /tmp/luau.zip https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip
mkdir -p /tmp/luaubin && python3 -c "import zipfile;zipfile.ZipFile('/tmp/luau.zip').extractall('/tmp/luaubin')"
chmod +x /tmp/luaubin/*
```

`/tmp` is wiped between sessions, so reinstall when `luau-compile` is missing.

## Verify before committing

```bash
/tmp/luaubin/luau-compile --binary inject.lua >/dev/null && echo OK
/tmp/luaubin/luau-compile --binary template.lua >/dev/null && echo OK
```

## Gotchas

- **`luau-compile` only catches syntax errors, not runtime errors.** A file can compile clean and still break at runtime. Always sanity-check API usage against the source.
- **Variable shadowing.** `inject.lua` used to declare `local FiveSync = Instance.new("ScreenGui")` inside `FiveSync.new` and `FiveSync:Loader`, which shadowed the library table and caused `_RandomString is not a valid member of ScreenGui`. The library is the table `local FiveSync = { ... }` (near the top); any GUI instance is named `ScreenGuiObj`. Never name a local `FiveSync`.
- **`AddToggle` returns an API table** (`SetValue` / `GetValue` / `SetText` / `GetText`), plus `Args.Link` for `AddKeybind` / `AddHelper` / `AddOption`. There is no `:Toggle()` method on the returned object.
- **`SetTheme` overwrites the whole palette**, so a config load can revert custom colors. `FiveSync.Colors` is the single source of truth.
- **Elements are only saved to config when they have a `Flag`.** Elements without a `Flag` are runtime-only.

## Workflow

- Open a PR for every finished change (base `main`).
- Keep the palette/brand consistent with the black & neon-white theme.
