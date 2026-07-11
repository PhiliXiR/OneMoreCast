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

As of this note, the local Godot 4.5, 4.6.1, and 4.7 console binaries all crash
on this machine even for a bare headless startup/quit command. That means the
validator is wired, but runtime validation may be blocked by the local Godot
installation or environment before the project is loaded.

Until that is resolved, use these checks before committing gameplay changes:

```powershell
git diff --check
```

Then manually open the project in Godot 4.7 and run the project from
`res://scenes/app/AppRoot.tscn`.

Do not treat a 4.5 or 4.6 validation failure as a project regression while the
project file targets 4.7.

For issue 58, Godot 4.7 successfully completed an editor filesystem scan and
registered `FishFightModel`, providing a usable script/scene parse check. The
full `validate_3d_prototype.gd` headless run still crashes with signal 11 before
the validator can report gameplay assertions.
