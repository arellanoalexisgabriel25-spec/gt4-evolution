# GT4 Evolution development

The runnable game lives in `godot/`. Preserve the original GT4 research documents and the separate reference checkout. Continue from the existing project; no recovered PS2 engine or commercial assets are integrated into the prototype.

## Working agreement

Develop functional increments on descriptive branches, preserve user work and save compatibility, run meaningful checks, prepare a PR and inspect CI before merging. Keep `main` stable. Use existing isolated checkouts; do not create a worktree unless requested. Continue routine technical work autonomously. Ask only for a missing prerequisite that cannot be resolved independently.

Current priority: develop a compact quarter-mile environment, manual shifting, measurable driving skill, persistent mechanical use and original visuals. Large-circuit expansion is deferred. Existing circuit, career and AI modes remain available. A simulated result must always be labelled as such.

## Architecture through 0.12

| Module | Responsibility |
| --- | --- |
| `vehicle_physics.gd`, `vehicle_config.gd`, `resources/*.tres` | Deterministic planar arcade dynamics and configurable handling |
| `transmission.gd` | Ratio-based RPM and sequential automatic shifting; not a torque/clutch simulation |
| `drag_vehicle_config.gd`, `manual_powertrain.gd` | Original approximate per-car mass/torque/gear data; substepped longitudinal engine/wheel inertia, finite clutch, grip/load transfer, drag, braking and session heat/stress |
| `drag_actor.gd`, `drag_strip.gd`, `drag_mode.gd` | Real collision body, original two-lane strip and manual input/timing/garage integration; directional assistance is explicit |
| `drag_run.gd`, `drag_records.gd`, `drag_garage_session.gd` | Interpolated beams, tree/false starts, validated personal tickets and once-only cumulative usage settlement |
| `drag_hud.gd`, `engine_audio.gd` | Measured manual telemetry/ticket and original provisional synthesized engine sound |
| `handling.gd` | Garage condition and installed parts translated into vehicle parameters |
| `vehicle_actor.gd` | Character body, collision, original provisional visual, measured distance and normalized controls |
| `chase_camera.gd` | Four independent views, damped heading/relative arm, rear/orbit input and wall avoidance |
| `car_visual.gd`, `car_preview.gd` | Original procedural vehicle bodywork/animation and isolated turntable viewport |
| `racing_theme.gd`, `city_map.gd`, `race_hud.gd`, `track_map.gd` | Shared visual style, navigable home, race telemetry and actual world-position minimap |
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

The source package is validated after fresh extraction. Windows includes the official Godot runtime verified against upstream SHA-512 and its license. Version 0.12 is also rendered at 1280×720 with OpenGL/Mesa llvmpipe on a local Xvfb display; actual screenshots are reviewed for menu layout, lighting, HUD and camera views. Windows execution, physical controllers and GPU performance remain untested. No claim of complete GT4 physics is made.

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

Human driving feedback and testing with physical controllers/GPU hardware; additional original circuits; broader physical career events; AI defending and more robust recovery in arbitrary crowded scenarios; realistic collision response/damage, tires, heat and engine torque; autosave with recovery. Preserve successful physical race tests and transaction guarantees when expanding these systems.

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

## Version 0.12: presentation and camera/steering response

See [RELEASE-0.12.md](RELEASE-0.12.md) for implementation and checks. Camera damping
now applies to heading and relative arm only; damping absolute world position
caused additional speed-dependent follow distance. Chase views shorten their arm
against real world barriers; bumper view hides only the player's visual node.
No collider or lap gate is moved by a camera change. Camera mode and keyboard
steering range are optional fields in the existing version-1 preference format.
The save format and transaction rules are unchanged.

Steering has independent turn-in/centring rates; turn-in slows with speed while
throttle retains its previous response. The keyboard range defaults to 80% and
can be adjusted from 40–100%; analog steering retains its full range. Visual
geometry and the preview share one procedural model, including steering/spinning
wheels and brake lights for pedal braking as well as the dedicated brake input.
The minimap renders the actual circuit polyline and actor positions.

`tools/capture_presentation.sh` uses temporary player data, checks renderer errors
and requires ten fresh PNGs. With an OpenGL display, run it with an absolute output
directory. CI uses Xvfb/software OpenGL and uploads the captures. Local cloud setup
also retains verified Debian Xvfb binaries under `/workspace/visual-runtime/` and
the helper `capture-game.sh`, which starts and stops its own display. Rendering
was checked with Mesa llvmpipe, including the home, dealer, garage, settings, four
views, rearward view and race grid. This establishes composition on that renderer,
not hardware performance or driving feel.

## Version 0.13: quarter-mile focus

The current increment is [RELEASE-0.13.md](RELEASE-0.13.md). The two-lane Autódromo
Sur is original and only takes broad inspiration from the Gálvez atmosphere.
The drag mode is individual practice: no admission fee, prize, license or simulated
opponent result is introduced. The existing garage unit supplies condition/tuning.

`manual_powertrain.gd` integrates separate engine and driven-wheel inertia with
240 Hz maximum substeps. Clutch torque is finite and depends on engagement and
condition. Gear changes are requested explicitly, require the clutch and interrupt
coupling for 0.18 seconds; there is no automatic change in this mode. Torque follows
RPM and engine condition; fuel cut and mechanical overspeed are distinct. Tire
force depends on slip, driven-axle load, grip, condition and approximate temperature.
Aerodynamic drag and rolling resistance use SI units. These are development presets,
not manufacturer measurements or a recovered GT4 physics implementation. Direction
is assisted; a full lateral tire/suspension model remains future work.

The scene uses actual CharacterBody movement for progress, distance and timing.
The tree turns green at two seconds; departure is measured after 0.20 m rollout.
Crossings of start, splits, trap entrance and finish interpolate within each physics
step. ET excludes reaction, total includes it; trap speed averages the last 20.1168 m.
Invalid attempts never create record tickets. Records are optional in the existing
career schema; numeric ticket fields are canonical floats after real JSON loading.

The garage adapter settles differences between cumulative distance/stress and
previous settlement counters, at finish, recovery and departure. Recovery keeps
heat and cumulative use but resets the attempt. Engine/gearbox/tire/brake stress is
separate from base odometer wear and never changes credits. The next session reads
the changed health from the persistent car. Workshop transmission repairs cover
the current clutch wear approximation; a separate clutch part is not yet modelled.

Three optional manual bindings extend the version-1 preference data. Old bindings
are not stolen: missing drag actions choose unused keys. Scene input consumes drive
actions before buttons can interpret Space. Controller drag mapping differs from
circuit mapping: A upshift, Y downshift, LB clutch, R3 rear view, Start arm/pause.

The four drag suites include physical complete runs, early/no-shift comparisons,
garage preset differences, engine stalls, overspeed, neutral and open clutch,
interpolated timing, invalid runs, actual JSON files, legacy controls and idempotent
usage settlement. The graphical capture adds actual manual arrival/false start and
checks audio pause on a real playback, since headless mode skips audio generation.
The capture driver is test-only; clear its Callable before changing scene to release
the captured script context. Sixteen PNGs are required by the capture wrapper.

Integration corrections: the supplied dynamics test called a missing `speed()` method, now exposed as planar velocity magnitude. The camera uses that magnitude so sideways drift does not incorrectly reduce its speed response. The same grip cap now applies to brake input and braking by selecting the opposite travel direction. Only actual propulsion applies driven-axle penalties; reverse-pedal deceleration is not treated as power. Added native tests cover both braking directions, drivetrain-independent pedal braking with equal axle bias, total speed and the camera's sideways-speed response. Save schemas and input preferences are unchanged. Windows/controller hardware and graphical appearance remain untested.
