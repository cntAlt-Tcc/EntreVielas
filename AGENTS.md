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
- **Luau caps locals at 200 per function/chunk.** A long top-level script can exceed this and fail with `Out of local registers when trying to allocate X: exceeded limit 200` (the executor compiles with optimization off, so it *does* enforce the limit even when a local `luau-compile` passes). Fix by wrapping self-contained groups of statements in `do ... end` blocks so their locals are released at the block end. Reproduce locally with `luau-compile --binary -O0 Script/A`.
- **The executor truncates pasted text at ~64000 characters.** Pasting a big script inline fails with an EOF parse error mid-table (`Expected '}' ... got <eof>`). Load it by URL instead: `loadstring(game:HttpGet(".../Script/A"))()`.
- **Always-on loops cost FPS even when their feature is off.** `Script/A` used to `Connect` every feature's `RenderStepped`/`Heartbeat` loop at load and bail out inside the callback. Connect the loop only when the feature's toggle turns on and `Disconnect` when it turns off (see `Aimbot_SetActive`, `SA_SetActive`, `ESP_SetEnabled`, `MB_SetState`). The toggle `Callback` runs once at load with the `Default`, so wiring it to a setter keeps initial state correct.
- **Always-on metamethod hooks get flagged as "IndexInstance".** `hookmetamethod(game, "__index", ...)` / `"__namecall"` installed at load is what anti-cheat "IndexInstance" detectors look for. Install the Silent Aim hooks only when the feature is active and the selected method needs them, and restore the original when off (see `SA_UpdateHooks`, called from the Silent Aim toggle and the method dropdown). With Silent Aim off, no `__index`/`__namecall` hook exists.
- **Silent Aim keeps its target fresh on `RenderStepped`.** `SA_TargetLoop` recomputes the closest in-FOV target every frame (and rolls `Hit Chance` once per frame into `SA_ChanceOK`); the hook itself only redirects. Do not move target acquisition back to a `task.wait` loop: a stale target position is the main cause of missed shots. `SA_ValidateArgs` gates each redirect on the real argument types so unrelated `Raycast`/`FindPartOnRay` calls are never corrupted. The method dropdown is multi-select (`Multi = true`); FiveSync passes a `{[value]=boolean}` map, so only keys whose value is `true` may be enabled.
- **Local runtime harness.** `/tmp/mock/roblox_mock.lua` is a fake Roblox env (services, players, Drawing, vector math, capture of RunService connections) built by `/tmp/mock/patch_mock.py`; `/tmp/mock/harness.py` loads mock + `inject.lua` + `Script/A` into one env. Run `/tmp/mock/dbg.py` then `/tmp/luaubin/luau dbg.lua` to execute the script end to end. `/tmp` is wiped between sessions, so rebuild it.

## Workflow

- Open a PR for every finished change (base `main`).
- Keep the palette/brand consistent with the black & neon-white theme.
