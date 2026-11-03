# GT4 Evolution development

The runnable game lives in `godot/`. Preserve the original GT4 research documents and the separate reference checkout. Continue from the existing project; no recovered PS2 engine or commercial assets are integrated into the prototype.

## Working agreement

Develop functional increments on descriptive branches, preserve user work and save compatibility, run meaningful checks, prepare a PR and inspect CI before merging. Keep `main` stable. Use existing isolated checkouts; do not create a worktree unless requested. Continue routine technical work autonomously. Ask only for a missing prerequisite that cannot be resolved independently.

Priorities: driving foundation, functioning circuit, physical rival AI, progressively replace simulated career events with real track results, then deeper mechanical systems. A simulated result must always be labelled as such.

## Architecture through 0.10

| Module | Responsibility |
| --- | --- |
| `vehicle_physics.gd`, `vehicle_config.gd`, `resources/*.tres` | Deterministic planar arcade dynamics and configurable handling |
| `transmission.gd` | Ratio-based RPM and sequential automatic shifting; not a torque/clutch simulation |
| `handling.gd` | Garage condition and installed parts translated into vehicle parameters |
| `vehicle_actor.gd` | Character body, collision, original provisional visual, measured distance and normalized controls |
| `chase_camera.gd` | Independent smoothed following camera |
| `circuit_layout.gd` | Original 456.7 m club oval, route sampling/projection, eight gates and their tangents |
| `circuit_view.gd` | Builds render geometry and collision barriers from the same layout used by timing and AI |
| `rival_driver.gd` | Pure control policy: pursuit target, curve speed, traffic braking, passing lane and deterministic profile variation; never moves the vehicle directly |
| `time_trial.gd` | Ordered directional crossings, valid laps, timing and interpolation at the finish |
| `race_session.gd` | Countdown, measured race progress, finish order, time limits, DNFs and three-second recovery holds; no economic side effects |
| `driving.gd` | Wires actors, controllers, timing, race HUD, pause and return to garage |
| `session.gd` | Runtime selection, race mode and admission lifecycle; rejects stale result callbacks |
| `career.gd` | Paid admission, validation and unique award for the physical debut event; legacy simulation for other events; licenses and rivalry history |
| `lap_records.gd` | Best valid lap per persistent car and circuit; validation and serialization |
| `economy.gd`, `tuning.gd` | Market, workshop, persistent mechanical state, fractional measured distance, wear and parts |
| `save_store.gd` | Validates decoded candidates, restores integral JSON numbers and writes via temporary-file replacement |
| `control_settings.gd` | Configurable physical keyboard bindings, fixed arrows, controller deadzones and normalized analog inputs; separate atomic preferences file |
| `main.gd` | Garage, market, workshop, career, tuning and save/load interface |

The research source and pinned commit are in REFERENCES.md. The new AI and race rules are original implementations, not ports of GT4's controller. Original research files remain unchanged.

## Economic and timing rules

Debutantes uses two physical laps against Nico and Claire, 120 Cr. admission, and one prize of 700 / 400 / 200 Cr. from the measured finish order. The career owns the paid entry; GameSession attaches it to the active race instance. Unpaid, unstarted, stale, malformed and duplicate awards are rejected. A scene that fails before attachment can refund admission once. Abandonment after attachment consumes it, pays nothing and leaves the event available for another paid attempt. The other four events remain explicitly simulated, preserving the existing progression.

Every completed valid lap can update a car's record. Off-road driving or a teleport invalidates the current attempt. A recovery starts a fresh attempt at the start, keeps completed laps, never adds teleport distance, and holds a racer for three seconds. Normal AI navigation completes laps without recovery. Stuck AI recovery is explicit and recorded. The race ends when all entrants are terminal, after 30 seconds of waiting following the player's finish, or at the 600-second limit. Unfinished entrants are DNFs, not fabricated finish times.

Measured distance and wear settle exactly once when returning to the garage, also on abandonment. Sub-kilometre metres accumulate across visits. A paid-entry transition cannot be saved as a garage state. Save/load remains manual; return and save after a race. New `distance_remainder_m` and `lap_records` fields are optional additions to existing schemas. Old completed events stay completed; no migration re-awards them.

## Validation

Use Godot 4.6.3, then run `bash tools/test_game.sh` from the repository root. The runner creates isolated XDG data/config/cache directories, imports resources, compiles all game scripts after autoload initialization, requires a PASS from every suite, rejects script/engine errors and tests main-scene startup. `--fixed-fps 60` accelerates deterministic test scenarios; it is not a performance benchmark.

The suite covers existing economy, career, inspections, tuning and transmission, plus real two-lap races with the same physical controller and collision world, overtaking, traffic decisions, checkpoint shortcuts, recovery, race timeout, fee/refund/award transactions, stale callbacks, fractional wear/distance, real JSON files, legacy saves and personal records. Local results do not establish a GitHub Actions pass. See the release report for counts and execution results.

The source package is validated after fresh extraction. Windows includes the official Godot runtime verified against upstream SHA-512 and its license; Windows execution and graphical appearance remain untested in this cloud environment. No claim of GUI performance or complete GT4 physics is made.

## Reusable setup and packaging

Use the existing Godot 4.6.3 installation. For manual cloud commands outside the isolated test runner:

```sh
export XDG_DATA_HOME=/workspace/.local/share/gt4-evolution
export XDG_CONFIG_HOME=/workspace/.config/gt4-evolution
export XDG_CACHE_HOME=/workspace/.cache/gt4-evolution
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path godot --editor --import
```

`python3 tools/package_game.py --output /path/to/output` creates the source ZIP. A portable Windows ZIP additionally requires `--windows-engine /path/to/Godot_v4.6.3-stable_win64.exe.zip --checksums /path/to/SHA512-SUMS.txt --engine-license /path/to/Godot-LICENSE.txt`. Use the official release and tagged source repository. Launchers import a fresh project before running it; caches are not bundled. The application data directory retains the original project name to preserve saved games; the displayed window title uses the current version.

This feature branch depends on the pending 0.8 and 0.8.1 increments; `main` remains unchanged until remote review and required CI can be confirmed.

## Remaining work

Human driving, graphical feedback and testing with physical controllers; additional original circuits; broader physical career events; AI defending and more robust recovery in arbitrary crowded scenarios; realistic collision response/damage, tires, heat and engine torque; autosave with recovery. Preserve successful physical race tests and transaction guarantees when expanding these systems.

## Version 0.10 and distribution

The settings menu rebinds seven keyboard actions without duplicate keys, leaves arrows and Escape available, and persists preferences separately from game progress. New Game preserves them. `vehicle_actor.gd` accepts brake strength while the physics API retains the existing boolean parameter for AI/backward compatibility. Controller B is reverse, not `ui_cancel` in the driving scene; driving inputs are consumed before focused buttons can act on them. Removing/rebinding a held action releases it to prevent stuck throttle.

Local download links from the chat were not accessible to the user. Release packages are now published on dedicated `downloads/vVERSION` branches, separate from main and development history. The branch README contains ordinary HTTPS download links. `tools/publish_downloads.py` verifies checksums, rejects files beyond GitHub's Git limit and refuses to overwrite a different existing release. Release updates are new version branches, not forced pushes. Normal Git push supplies publication when the Releases API is unavailable. Verify each published link by downloading it and comparing its SHA-256 before reporting it accessible. Distribution branches are not merged into main.

Run the existing strict suite for controls and driving regression. The input tests cover physical key events, focus safety, pause/recovery, preferences files and normalized controller samples. They do not establish hardware compatibility or Windows execution.

## Version 0.11: submitted driving dynamics

The supplied files were originally marked unverified in Godot and checked only in a Python port. Integration was therefore checked with the actual Godot 4.6.3 engine, including the complete race and persistence suites. The original ZIP and patch are retained separately under `/workspace/references/user-changes-0.11/`; unchanged files and generated UIDs were not overwritten.

- `vehicle_config.gd`: new exports `torque_curve`, `front_weight_bias`, `drag_taper`, `brake_grip_factor`, `yaw_grip_overdrive`.
- `vehicle_physics.gd`: engine torque follows RPM and fades near top speed; axle loads follow weight transfer (`axle_grip()`), unloading the front on power and the rear under braking; only applied drive power loads the driven axle (braking no longer applies drivetrain penalties); braking deceleration is capped by tire grip so worn tires lengthen stopping; yaw rate saturates near the grip limit so full lock at speed slides wide instead of spinning the heading.
- `resources/*.tres`, `handling.gd`: front-drive cars are front-heavy (0.62) with an earlier-peaking torque curve; AWD uses 0.55.
- `chase_camera.gd`: heading is smoothed so slides stay visible; distance, height, look-ahead and field of view grow with speed. Public API (`target`, `response`, `snap()`) is unchanged.
- `tests/test_vehicle_dynamics.gd`: torque curve, drag taper, axle loads, braking distance versus tires/brakes, power/coast/brake cornering per drivetrain, yaw saturation, preset differences and camera behaviour.

Known trade-offs: braking from 30 m/s with default tires now takes about 20.6 m (was about 17.7 m); AI target speeds are unchanged; native scene tests measure the new lap times rather than assuming they match the Python estimate. Weight transfer is still a single-body approximation, not a two-axle tire model.

Integration corrections: the supplied dynamics test called a missing `speed()` method, now exposed as planar velocity magnitude. The camera uses that magnitude so sideways drift does not incorrectly reduce its speed response. The same grip cap now applies to brake input and braking by selecting the opposite travel direction. Only actual propulsion applies driven-axle penalties; reverse-pedal deceleration is not treated as power. Added native tests cover both braking directions, drivetrain-independent pedal braking with equal axle bias, total speed and the camera's sideways-speed response. Save schemas and input preferences are unchanged. Windows/controller hardware and graphical appearance remain untested.
