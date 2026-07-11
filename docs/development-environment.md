# Development Environment

One More Cast currently targets Godot 4.7.

The local Godot executable used for project validation is:

```text
C:\_Dev\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe
```

The prototype validation command is:

```powershell
C:\_Dev\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe --headless --path C:\_Dev\OneMoreCast --script scripts\validate_3d_prototype.gd
```

The menu integration validation command is:

```powershell
C:\_Dev\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe --headless --path C:\_Dev\OneMoreCast --script scripts\validate_menu_integration.gd
```

The project file also records the 4.7 feature version:

```text
config/features=PackedStringArray("4.7")
```

## Current Validation Note

The Godot commands must be run with normal access to the user's Godot data
directory. A restricted filesystem sandbox can prevent Godot from creating
`user://logs` and cause the native process to crash with signal 11 before a
project is loaded. That is an environment failure, not a One More Cast
regression.

Use these automated checks before committing gameplay changes:

```powershell
git diff --check
C:\_Dev\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe --headless --path C:\_Dev\OneMoreCast --quit-after 1
C:\_Dev\Godot\Godot_4.7\Godot_v4.7-stable_win64_console.exe --headless --path C:\_Dev\OneMoreCast --script scripts\validate_menu_integration.gd
```

Run `scripts\validate_3d_prototype.gd` as the broader gameplay check. On the
2026-07-11 baseline it reaches project assertions but reports the existing
synthetic cast-button input failure. Treat new failures or a changed failure as
regressions; the known assertion does not indicate a native engine crash.

If a headless command crashes before printing validator output, repeat a bare
startup against One More Cast and a blank Godot 4.7 project with the same
permissions. A crash in both projects is an engine or environment problem. A
validator assertion, script parse error, or failure isolated to One More Cast is
a project regression and must be fixed.

The manual validation route is to open the project in the Godot 4.7 editor, run
`res://scenes/app/AppRoot.tscn`, enter the playable level, and exercise the
changed interaction. For an interactive fish fight, confirm that reeling,
yielding, line tension feedback, landing progress, a landed fish, line break,
and thrown hook can each be observed as appropriate to the change.

Do not treat a 4.5 or 4.6 validation failure as a project regression while the
project file targets 4.7.

## Godot 4.7 Investigation Result

The issue 59 investigation was time-boxed and completed on 2026-07-11 with
Godot 4.7 stable (`5b4e0cb0f`) on Windows:

- Restricted headless startup crashed with signal 11 for both One More Cast and
  a minimal blank project after failing to create `user://logs`.
- With normal filesystem access, One More Cast headless startup and the blank
  project's headless editor startup both exited successfully.
- The Godot 4.7 editor opened the project, initialized the OpenGL compatibility
  renderer, and exited successfully after 180 frames. A separate normal project
  run (`--path C:\_Dev\OneMoreCast --quit-after 180`) exercised
  `AppRoot.tscn`, produced no console errors, and also exited successfully.
- The menu integration validator passed. The prototype validator reached its
  cast-button project assertion after its warning-as-error parse findings were
  corrected, proving that the unrestricted headless route reports
  project-specific failures.

Contributors can therefore continue using unrestricted headless validators for
automation and Godot 4.7 editor play for interaction and game-feel checks. A
restricted-sandbox native crash should be recorded separately and must not
block the remaining interactive fish-fight work.
