$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..'
$batch = Join-Path $root 'assets\_review\generated\issue-67-dock-bluegill'
$scratch = Join-Path $root 'assets\_scratch\issue-67-dock-bluegill-preview'
$godot = (Get-Command godot.cmd -ErrorAction SilentlyContinue).Source
if (-not $godot) { throw 'Godot executable not found on PATH.' }
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
Copy-Item (Join-Path $batch 'dock_bluegill.glb') (Join-Path $scratch 'dock_bluegill.glb') -Force
Copy-Item (Join-Path $root 'fish\dock_bluegill_review_preview.tscn') (Join-Path $scratch 'dock_bluegill_review_preview.tscn') -Force
Copy-Item (Join-Path $root 'fish\dock_bluegill_review_preview.gd') (Join-Path $scratch 'dock_bluegill_review_preview.gd') -Force
Copy-Item (Join-Path $root 'scripts\validate_dock_bluegill_review.gd') (Join-Path $scratch 'validate_dock_bluegill_review.gd') -Force
& $godot --headless --path $root --editor --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot Compatibility import scan failed.' }
& $godot --headless --path $root --script 'res://assets/_scratch/issue-67-dock-bluegill-preview/validate_dock_bluegill_review.gd'
if ($LASTEXITCODE -ne 0) { throw 'Godot Compatibility import failed.' }
Write-Host 'Dock Bluegill candidate imported under Compatibility renderer.'
