# Water Lens policy comparison

Issue #95 compares the three shot policies with repeatable recovery, surge,
line-break, thrown-hook, and landing snapshots at 1920x1080, 1280x720, and
390x844. `scripts/validate_water_lens.gd` verifies that the hooked fish and
the active line direction remain within the Water Lens frame, and that the
Water Lens never overlaps the Reel/Yield action strip.

| Policy | Recovery | Surge / danger | Landing | Decision |
| --- | --- | --- | --- | --- |
| Water Read | Wide | Wide | Landing | Safest context, but less immediate fight feedback. |
| Line Pull | Pursuit | Close-up when line endpoints fit; pursuit fallback | Landing | **Recommended default.** It makes Reel/Yield consequences most legible without sacrificing the fish or line direction. |
| Landing Focus | Pursuit | Close-up when clear; pursuit fallback | Landing early | Useful as a presentation experiment, but it moves toward the reveal before the fight decision has resolved. |

## Follow-up camera experiments

- Test a fish-orientation marker or subtle travel trail so direction of travel
  can remain explicit even when the hooked fish changes speed.
- Revisit the close-up distance after the Dock Bluegill model and underwater
  lighting receive their final scale and contrast pass.
- Compare a line-tension-tinted frame against the current caption-only danger
  signal, preserving the same reduced-motion presentation.
