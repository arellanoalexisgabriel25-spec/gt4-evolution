# GT4 Evolution development

The runnable game lives in `godot/`. Preserve the original GT4 research documents and the separate reference checkout. Continue from the existing project; no recovered PS2 engine or commercial assets are integrated into the prototype.

## Working agreement

Develop functional increments on descriptive branches, preserve user work and save compatibility, run meaningful checks, prepare a PR and inspect CI before merging. Keep `main` stable. Use existing isolated checkouts; do not create a worktree unless requested. Continue routine technical work autonomously. Ask only for a missing prerequisite that cannot be resolved independently.

Current priority: develop a compact quarter-mile environment, manual shifting, measurable driving skill, persistent mechanical use and original visuals. Large-circuit expansion is deferred. Existing circuit, career and AI modes remain available. A simulated result must always be labelled as such.

## Current increment: 0.21

`technical_reference_data.gd` holds exact supplied 1997 Vivace anchors and PDF hash. Both catalog/circuit and stock drag configuration consume those constants. 63CV,10.4kgfm and807kg are user-compilation claims; power RPM5500, fuel/mass convention, gearing and interpolation remain estimates. `tools/benchmark_stock.gd` reports a numerical90s protocol rather than factory/scene measurements. No other grouped variant overwrites a better-identified prior reference.

`DragRecords.consider_for_profile`/`best_for_profile` isolate changed physical revisions while keeping unversioned historical tickets readable. The first new valid finish archives the previous active ticket; slower or invalid repeats cannot mutate history. Career JSON accepts absent `drag_record_history`/`stock_drag_record_history` for previous saves. Standard unversioned caller behavior remains compatible. A revised ticket cannot be relabelled as another profile.

`racing_theme.gd` centralizes the supplied GT4_UI_System colors, rounded subtle panels, focus states and OFL fonts. Main services, preview stage/map, pause and both HUDs share it. Monospaced racing digits do not change advance widths. New functional layout checks exercise1280×720 and1280×800; driving controls/HUD visibility remain unchanged.

## Previous increment: 0.20

`drag_start_procedure.gd` owns the pure starter state (25s warm-up,30s staging,1.5s continuous ready hold). These durations are game policy, not the supplied regulation. `drag_mode.gd` advances it only during unpaused physics, samples both actual cars, and arms their existing timing runs once. Enter is no longer a start input. Authorized warm-up is ahead of the line; the disclosed staging assist brakes, aligns and holds before timing, preserving heat/wear/odometry and resetting only acceleration metrics. No reverse-gear return is claimed. Leaving the local2.5–35m zone or missing the call cancels this exhibition preparation, not an official championship penalty ladder.

Rear parking brake H/L3 is independent of hydraulic ABS; Manual/axles dissipate physical slip and brake energy with existing torque limits. There is no temperature bonus or forced stationary burnout. `request_shift` buffers pedal/lever ordering for0.10s without lifting throttle or auto-clutching. Legacy strict `shift` remains for scripted drivers. The HUD keeps compact instruments in the pass, diagnostic/help in pause.

Six older models now use external1024² mipmapped textures, including Gol's three PBR maps; geometry/UV/accessor bytes remain identical. Original files remain in references. See RELEASE-0.20.md and asset provenance for measured resource sizes and validation limits.

## Previous increment: 0.19

Seven new models are authored once in `additional_vehicle_data.gd`, consumed by catalog and stock specifications. Stable names and IDs 17–23 extend the previous sixteen offers; legacy offers, saves and finances stay unchanged. Distinguish a supplied guide claim from an estimated parameter or a body scan's appearance. The 500 uses the user's explicit Sport 100 CV reference, with the supplied Abarth body still labelled provisional; do not infer turbo/Abarth performance from graphics.

`GameSession.start_drag` has a fifth optional supported opponent model. Empty preserves the previous same-model duel. The AI car is a deep copy configured independently and cannot mutate the seller's unit. Invalid formats/models reject atomically before player selection. Garage choice persists during the session, not as a new save schema. Damage's fourth optional engine position defaults to legacy front allocation, with explicit rear/mid compartment redistribution that conserves severity. Manual shifting rejects malformed clutch values without mechanical side effects; valid clutch mistakes still wear the transmission.

Runtime textures and visual wheel geometry are separate from physical wheelbase/radius. Seven sources use explicit mipmapped PNG imports; the Gol's original GLB is unchanged and its import compresses embedded textures. Optimize originals only into separate derivatives. `presentation_shots.txt` is the single expected-capture list used by rendering checks and publication.

## Historical increment: 0.18

Three appended classic offers retain IDs 1–13: 128 Súper Europa 1.5 (ID14), rear-drive 133 (ID15), standard 128 (ID16). `Catalog.FLAGSHIPS` remains the original three; `CLASSICS` and `has_definition` separate market priority from supported profiles. Legacy offer migration remains idempotent and collision-safe. Supplied manufacturer-report claims and estimated fields remain distinct.

`track_surface.gd` owns visible strip boundaries and dry surface presets. Four world collision raycasts in DragActor exclude vehicle layers and aggregate front/rear support, grip and rolling resistance. `Manual.step` accepts optional `contact_state` without changing legacy pure-model callers. Missing support removes tire force/road heating/rolling drag, while engine torque and wheel/brake inertia remain. Aerodynamic drag and gravity continue in flight. Surface transitions cap relaxed tire forces at the current μN. Brake heat uses exact pre/post rotational energy removed by the braking operator. This is longitudinal contact handling, not a full suspension or lateral tire solver.

`imported_car.gd` additionally segments the new classic wheels by their lower contour, retaining bright hubcaps and original UVs. The GLBs in the previous release remain byte-identical. Windows distribution uses official Godot 4.6.3 export templates, a verified executable and PCK instead of the editor. `tools/release_artifacts.py` handles manifests and PCK integrity; Linux checks run the identical PCK. See RELEASE-0.18.md for exact validation results and limits.

## Historical increment: 0.17

See [RELEASE-0.17.md](RELEASE-0.17.md) for implementation scope and the validation
status of this exact source state. New user-supplied plain texts enable Article 21
quarter-mile floors and an Article 12 false-start exception; earlier network failures
are historical, not evidence that the newly supplied regulations were unavailable.
[REGULATIONS-REFERENCE.md](REGULATIONS-REFERENCE.md) records the source hashes,
article references, mixed distances, contradictory eighth-mile class 6 values,
unspecified tree timing and the absence of a run-level tie rule.

The exact garage entry is **DUELO ¼ DE MILLA / FÁBRICA**. The menu selects a rival
and a quarter-mile class, defaults to class 1 / 18.00 s ET, and offers a free
first-arrival option. Official L1 admission is deliberately not exposed as that
free option: its sporting-text admission conditions are not modelled. The selected
class reaches the scene through GameSession; legacy `start_drag(id)` remains
individual practice. Only indexed duels use the `argentina_reference` judging
profile. ET determines breakout; RT + ET determines valid arrival order. A single
false start grants the other lane victory regardless of its ET, as Article 12
specifies. Double-invalid runs do not fabricate a winning time. This is one free
exhibition round, without championship, entry-fee settlement, cash awards, repechage,
final reruns or trophies. Documentation of those rules does not implement them.

Factory configuration is an explicit game restriction, separate from the technical
regulation's Serie definition, which permits mechanical preparation. Existing
health, usage settlement, manual saves and separate stock records are retained.
Do not present estimated engine/gear/mass presets as manufacturer specifications;
V6 data has not been obtained and performance calibration remains future work.

New supplied 147 and Uno GLBs have roughly one million triangles each; render
derivatives are optimized with UV/material preservation, while originals are
retained separately. Both final derivatives contain 79,998 triangles, with byte-identical source textures.
Their hashes and visual checks are recorded in the release report. The supplied Gol is unchanged. Visual inspection
identifies the Uno mesh as five-door, although the catalogue's intended variant
remains three-door. This is an asset limitation, not evidence of a different
manufacturer powertrain or a reason to silently alter the catalogue variant.
Final asset counts and source-state test/capture results belong in the release
report after measurement; no previous release's passing count certifies 0.17.

## Architecture through 0.19

| Module | Responsibility |
| --- | --- |
| `vehicle_physics.gd`, `vehicle_config.gd`, `resources/*.tres` | Deterministic planar arcade dynamics and configurable handling |
| `transmission.gd` | Ratio-based RPM and sequential automatic shifting; not a torque/clutch simulation |
| `drag_vehicle_config.gd`, `manual_powertrain.gd` | Original approximate per-car data; 480 Hz maximum substeps for engine/clutch, torque and driveline efficiency; wires independent axles and session wear |
| `engine_torque.gd`, `axle_traction.gd` | RPM torque interpolation and transient turbo; independent front/rear rotation, slip, load, tire force, heat, brake torque and ABS modulation |
| `tire_model.gd`, `damage_model.gd` | Adapted supplied modules: per-axle slip-energy temperature/tread, compound windows, actual collision damage and validated settlement |
| `car_catalog.gd`, `imported_car.gd`, `assets/cars/` | Three flagship presets and stable market order; supplied Gol and optimized supplied 147/Uno render meshes, normalization, UV/material preservation and independent colliders |
| `track_surface.gd` | Shared finite visual surface bands and four-wheel support/coefficients aggregation |
| `drag_actor.gd`, `drag_strip.gd`, `drag_mode.gd` | Real collision body, original two-lane strip and manual input/timing/garage integration; directional assistance is explicit |
| `drag_run.gd`, `drag_records.gd`, `drag_garage_session.gd` | Interpolated beams, tree/false starts, validated personal tickets and once-only cumulative usage settlement |
| `drag_class_rules.gd` | Independent quarter/eighth-mile Article 21 tables and strict ET floor evaluation; source metadata makes admission/safety limits explicit |
| `drag_duel.gd`, `drag_rival_driver.gd` | Two-lane adjudication with explicit legacy/reference profiles and reproducible pedal/clutch/shift-only rival policy |
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
| `economy.gd`, `tuning.gd`, `money.gd` | Market, workshop, persistent state, wear and parts; consistent ARS formatting and currency metadata without changing ledger proportions |
| `save_store.gd` | Validates decoded candidates, restores integral JSON numbers and writes via temporary-file replacement |
| `control_settings.gd`, `controller_state.gd` | Physical bindings, cached actual Godot controller events, normalized analog inputs and active-device changes; separate atomic preferences including aids, clutch and music volume |
| `menu_controller.gd`, `pause_menu.gd` | Repeated stick/D-pad focus navigation, debounced purchases, settings, tabs and in-race continue/recover/garage overlay |
| `menu_music.gd`, `assets/audio/` | User-supplied MP3 with redistribution authorization; persistent looping player, independent volume and scene fades |
| `main.gd` | Garage, market, workshop, career, tuning and save/load interface |

The research source and pinned commit are in REFERENCES.md. The new AI and race rules are original implementations, not ports of GT4's controller. Original research files remain unchanged.

## Economic and timing rules

Debutantes uses two physical laps against Nico and Claire, $ 120,000 ARS admission, and one prize of $ 700,000 / $ 400,000 / $ 200,000 ARS from the measured finish order. The integer ledger retains its old granularity: each stored unit represents ARS 1,000. The career owns the paid entry; GameSession attaches it to the active race instance. Unpaid, unstarted, stale, malformed and duplicate awards are rejected. A scene that fails before attachment can refund admission once. Abandonment after attachment consumes it, pays nothing and leaves the event available for another paid attempt. The other four events remain explicitly simulated, preserving the existing progression.

Every completed valid lap can update a car's record. Off-road driving or a teleport invalidates the current attempt. A recovery starts a fresh attempt at the start, keeps completed laps, never adds teleport distance, and holds a racer for three seconds. Normal AI navigation completes laps without recovery. Stuck AI recovery is explicit and recorded. The race ends when all entrants are terminal, after 30 seconds of waiting following the player's finish, or at the 600-second limit. Unfinished entrants are DNFs, not fabricated finish times.

Measured distance and wear settle exactly once when returning to the garage, also on abandonment. Sub-kilometre metres accumulate across visits. A paid-entry transition cannot be saved as a garage state. Save/load remains manual; return and save after a race. New `distance_remainder_m` and `lap_records` fields are optional additions to existing schemas. Old completed events stay completed; no migration re-awards them.

## Validation

Use Godot 4.6.3, then run `bash tools/test_game.sh` from the repository root. The runner creates isolated XDG data/config/cache directories, imports resources, compiles all game scripts after autoload initialization, requires a PASS from every suite, rejects script/engine errors and tests main-scene startup. `--fixed-fps 60` accelerates deterministic test scenarios; it is not a performance benchmark.

The suite covers existing economy, career, inspections, tuning and transmission, plus real two-lap races with the same physical controller and collision world, overtaking, traffic decisions, checkpoint shortcuts, recovery, race timeout, fee/refund/award transactions, stale callbacks, fractional wear/distance, real JSON files, legacy saves and personal records. Local results do not establish a GitHub Actions pass. See the release report for counts and execution results.

The source package is validated after fresh extraction. Windows includes the official Godot runtime verified against upstream SHA-512 and its license. The graphical checks render at 1280×720 with OpenGL/Mesa llvmpipe on a local Xvfb display; actual screenshots are reviewed for menu layout, lighting, HUD and camera views. Windows execution, physical controllers and GPU performance remain untested. No claim of complete GT4 physics is made.

## Reusable setup and packaging

Use the existing Godot 4.6.3 installation. For manual cloud commands outside the isolated test runner:

```sh
export XDG_DATA_HOME=/workspace/.local/share/gt4-evolution
export XDG_CONFIG_HOME=/workspace/.config/gt4-evolution
export XDG_CACHE_HOME=/workspace/.cache/gt4-evolution
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path godot --editor --import
```

`python3 tools/package_game.py --output /path/to/output` creates the source ZIP. A standalone Windows ZIP requires `--export-templates /path/to/Godot_v4.6.3-stable_export_templates.tpz --checksums /path/to/SHA512-SUMS.txt --engine-license /path/to/Godot-LICENSE.txt --engine-copyright /path/to/Godot-COPYRIGHT.txt`. Use the official release and tagged source repository. Windows runs its exported PCK without importing a project or bundling the editor; the source ZIP is freshly imported for validation. The application data directory retains the original project name to preserve saved games; the displayed window title uses the current version.

The feature branch includes the earlier pending increments; `main` remains unchanged until review and required CI can be confirmed. Git access and GitHub API access are separate: when the API is unavailable, inspect public Actions run/job pages for the exact source commit before reporting CI status.

## Remaining work

Human driving feedback and testing with physical controllers/GPU hardware; calibrated tire and engine data, lateral dynamics, left/right differentials and realistic collision response/damage; broader physical career events and robust AI in crowded scenarios; autosave with recovery. Large-circuit expansion remains deferred. Preserve successful race tests and transaction guarantees when expanding these systems.

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

## Version 0.14: traction, ARS, menu music and controller

See [RELEASE-0.14.md](RELEASE-0.14.md). The new longitudinal model applies only to
quarter-mile mode; the club circuit retains its tested planar controller. Axle
normal loads conserve `mass * g`, with filtered acceleration transferring load.
Tire force peaks near 12% slip and declines toward a sliding plateau. Force
relaxation is clamped against reversed slip to avoid adding energy. Independent
axle rotation drives the procedural wheel animation. Brakes apply wheel torque;
there is no additional artificial chassis braking force. ABS reduces brake torque
for measured lock slip. Optional TCS cuts combustion for positive driven-wheel
slip; neither aid increases tire grip. Engine curves have explicit RPM knots,
turbo builds/decays with load, and driveline losses depend on the preset.

Ledger integers are deliberately preserved, including fees and transaction history.
`Money.format()` renders one ledger unit as ARS 1,000, using local thousands
separators. Economy serialization adds optional `currency_code`/`money_unit_ars`;
legacy saves without either remain valid. Incomplete or incompatible metadata is
rejected before modifying runtime state. No repeated load can compound balances.
Prices are fictional game values, not a conversion against an external exchange rate.

`ControllerState` caches SDL/Godot events and clears device state on disconnect.
Menu navigation consumes input before callbacks that may detach the page. Held A
cannot repeat a purchase or leak into the next scene as an upshift. Pause callbacks
release focus synchronously. Disconnecting the active controller pauses both modes;
the keyboard remains available. Optional LT clutch applies only to drag mode,
leaving B as an independent brake even while RT is held. New preferences are
optional in the version-1 format and stored apart from manual game saves.

The menu MP3 is unchanged from the user's upload; its SHA-256, title, credits and
redistribution authorization are recorded under `assets/audio/`. It is not relicensed
under MIT. A persistent AudioStreamPlayer loops the MP3, fades out on track entry,
and returns at its saved position. Volume is independent and validated atomically.
Headless tests load/decode the real stream; graphical checks assert real playback,
looping and fade to silence. The package and publisher include and byte-check MP3s.

Four new suites cover axle forces/energy/braking/boost/aids, ARS/legacy JSON,
actual audio/preferences and controller-driven purchases/settings/scene changes.
The current capture wrapper requires seventeen PNGs, including the pause overlay.
Focused buttons use explicit dark text on the light theme to retain contrast.

## Historical version 0.15: flagship cars and reviewed mechanics

This section records the 0.15 delivery. Its 147/Uno transfer and placeholder limits
were superseded by the supplied ZIP integration in 0.17; keep them as provenance,
not as the current asset state.

See [RELEASE-0.15.md](RELEASE-0.15.md) and the specific technical decision in
[INTEGRATION-CLAUDE-0.11d.md](INTEGRATION-CLAUDE-0.11d.md). The supplied originals
are retained outside the checkout at `/workspace/references/user-changes-0.15/`.
Only `tire_model.gd` and the impact portion of `damage_model.gd` are adopted.
The supplied replacement run/spec/tree/settlement modules are incompatible with
the existing physical scene and cumulative settlement and are not copied over them.

The 147, Uno and Gol are appended as IDs 11–13. The first ten seed entries retain
their names, health, prices and IDs. Menu loading adds missing flagship offers
idempotently; an occupied custom ID is preserved and a fresh ID allocated instead.
Each flagship is FWD in both modes and has independent dimensions, approximate
mass, torque and gear ratios. Home selectors and garage preview buttons are real
menu actions. The national range is shown first without sorting persistent arrays.

The supplied Gol GLB is unchanged and includes 40,000 triangles and embedded PBR
textures. Runtime normalization and cached mesh partition preserve all geometry,
UVs and material. Wheel regions are refined with neutral/dark diffuse texels so
painted fenders remain part of the body; visual pivots come from separated geometry.
The colliders remain simple per-car boxes. The two larger model attachments exceed
the 32 MiB transfer limit; the alternate Drive link is denied by the current proxy.
Drive domains are already in the configuration draft but not applied to the runtime.
The 147/Uno use distinct original procedural placeholders pending actual inspection.
Do not describe those two supplied models as imported or verified.

Each axle owns a Tire model. Contact updates receive measured slip dissipation,
normal force, tire force and speed, not chassis acceleration. Tread adds monotonically
to the existing mechanical wear counter; contact grip uses compound/temperature
without reapplying the same session tread loss. The old upgrade maps to sport tires
and its old grip multiplier is not stacked with the sport peak in drag mode.
Paid tire replacement is validated atomically, restores tire health and records a
single debit. The optional `tire_compound` persists under the same save schema;
invalid values are rejected. Circuit physics retains its controller and reads the
selected compound only as a base-grip choice.
Sport/slick mounting synchronizes the existing `tires` upgrade flag, so Tuning
cannot sell that same improvement a second time. Returning to street tires removes
the flag without a refund; both interfaces describe the same installed set.

DragActor measures impact velocity loss only around a real wall collision after
propulsion/braking. Damage alters current powertrain parameters immediately and
settles pending health loss via the existing garage adapter. Recovery preserves
damage, heat and cumulative use. Invalid pending damage is rejected before distance
changes; repeated settlement never duplicates it. The visit's damage report remains
visible independently of pending settlement. An unroadworthy unit cannot arm another
pass; repair and return to the garage remain available. Electronic limiting is not
classified as an impact or mechanical over-rev; existing clutch/overspeed wear remains.

The current graphical wrapper requires 24 images, adding the three showroom
choices, tire workshop, supplied Gol staging/driving and an impact against the actual
runoff barrier. It checks the supplied Gol's real manual launch. Source packaging and
publication include and byte-compare `.glb` assets as well as the existing MP3/font.
Pin `gltf/embedded_image_handling=3` on the supplied GLB: default extraction creates
external PNG dependencies. Embedded uncompressed images preserve the original data
inside the imported scene. Only the generated external duplicates were removed;
the uploaded GLB is unchanged. Packaging also supports explicit `.png` assets.
Use the current complete suite and fresh-package checks; historical release counts
and the stored setup description are not evidence for this new source state.

## Historical version 0.16

See [RELEASE-0.16.md](RELEASE-0.16.md) and [STOCK-SOURCES.md](STOCK-SOURCES.md). At the 0.16 delivery, official sites were blocked and regulations had not been supplied as readable text. Profiles remain development estimates. The UI default drag entry introduced a physical factory-configuration duel. Legacy start_drag(id) stays practice; start_drag(id,"duel",profile) selects two cars on a shared tree, independent interpolated tickets and pure RT+ET adjudication. Separate lamps preserve the rival green after player disqualification. Pause/recovery cover both cars; AI only writes pedal/clutch/shift inputs. No fees/prizes.

Factory ignores upgrades while retaining garage health and equipment. Optional stock_drag_records preserve legacy saves and isolate prepared/old times. Actor0–100 starts at0.1m/s, interpolates crossings and resets on arming so staging cannot pollute it. Peer camera framing only affects chase mode0.

Net torque avoids double friction at WOT; negative/backdrive efficiency must dissipate energy. Engine, shaft and contact power are separate. Analytical power peaks and game benchmarks do not establish manufacturer performance. Fuel basis and exact variants remain unverified. Capture wrapper requires27 PNGs.


The Uno Fire 1.3 8V 3-door 2014 now uses two manufacturer-report claims transcribed by the user: 68 metric CV at 5250 rpm and 11.3 kgf·m at 2250 rpm. Explicit unit conversions constrain the full-load curve; 13.2 s 0–100 and 158 km/h are reference targets, never a velocity/acceleration override. Remaining engine points, mass and gearing remain estimates. See STOCK-SOURCES.md and FIAT-REPORT-REVIEW.md.
