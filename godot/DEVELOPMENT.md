# GT4 Evolution development

The standalone game lives in `godot/`; preserve the original GT4 research documents separately. Continue from the existing project. Do not imply that the commercial engine, assets or advanced simulation have been recovered for this prototype.

## Working agreement

Develop in functional increments on a descriptive branch based on current `main`. Implement and test changes, prepare a pull request, inspect CI and merge only after required checks pass. Keep `main` stable. Preserve save compatibility, existing work and research. Avoid unnecessary dependencies and commercial assets without suitable rights. Continue routine technical work autonomously; ask only for a prerequisite that cannot be resolved independently.

The progression priorities are improved driving, a functioning circuit, physical rival AI, real race results integrated with career, then deeper mechanical systems. Keep vehicle physics, persistent vehicle data, economy, market, workshop, tuning, career, AI, timing, UI and persistence separate. A simulated career result is not a physically contested race.

## Version 0.8 implementation

- `vehicle_physics.gd`: deterministic planar arcade dynamics, progressive inputs, limited lateral tire acceleration, slip and recovery, simplified longitudinal weight transfer, FWD/RWD/AWD responses, reverse, automatic gear and RPM display.
- `vehicle_config.gd` and `resources/*.tres`: tunable vehicle presets. `handling.gd` selects a preset for existing garage models and applies mechanical health and installed parts. Parameters are provisional game balance, not recovered manufacturer or GT4 values.
- `chase_camera.gd`: independent, exponentially smoothed camera with immediate recovery snap.
- `driving.gd`: garage integration, collision body, provisional car visuals, original closed circuit, off-road slowdown and driving HUD.
- `time_trial.gd`: ordered, directional checkpoint crossings, lap times and session best. Recovery and teleports invalidate current progress. Completed lap times survive recovery but are not saved between scene visits.
- Existing economy and career save schemas remain unchanged. Track laps do not pay career rewards. Sub-kilometre distances still do not accumulate across visits; collision damage and tire temperatures are pending.

## Reproduction

Use Godot 4.6.3. In cloud sessions use writable XDG directories outside the checkout:

```sh
export XDG_DATA_HOME=/workspace/.local/share/gt4-evolution
export XDG_CONFIG_HOME=/workspace/.config/gt4-evolution
export XDG_CACHE_HOME=/workspace/.cache/gt4-evolution
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
bash tools/test_game.sh
```

The strict runner imports the project, requires a PASS from every test script, rejects engine/script errors, and starts the main scene. This increment passed 10 suites / 175 assertions in headless Linux. Tests cover driving and garage return, presets, wear and tuning, braking, reverse, slip recovery, axle differences, determinism, tick rates and invalid lap shortcuts. GUI rendering, Windows execution, full player-driven laps and race AI have not been validated.

`.github/workflows/godot-tests.yml` installs the official engine after SHA-512 verification and uses the same runner. Remote CI must be checked separately; local results do not establish a GitHub Actions pass.

`python3 tools/package_game.py --output /path/to/output` creates a source ZIP. To include the official Windows engine, provide `--windows-engine /path/to/Godot_v4.6.3-stable_win64.exe.zip --checksums /path/to/SHA512-SUMS.txt --engine-license /path/to/Godot-LICENSE.txt`. Download these from the official Godot release and its tagged source repository. The script rejects a checksum mismatch and includes the engine license. The portable launcher imports a fresh project before starting it; no cache from the developer machine is required.

## Next increment

Validate complete driving laps and collision recovery under reproducible navigation scenarios, refine the handling with player feedback, then implement waypoint-following physical rivals with curve anticipation and collision avoidance. Preserve simulated career events until real race completion and reward accounting are covered by integration tests.

## Version 0.8.1

Added independent configurable transmission telemetry and sequential automatic shifting after inspection of the supplied gt4-decomp repository. See REFERENCES.md for exact source paths and boundaries. The strict runner passed 11 suites / 190 assertions. Existing save schemas are unchanged. This branch depends on the pending version 0.8 feature branch; main is not merged or reset.
