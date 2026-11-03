# GT4 research references

Source: [gustavocanepa/gt4-decomp](https://github.com/gustavocanepa/gt4-decomp), branch `master`, inspected commit `122afce110f76738720f5c0dfdfc410c5d08a62e`.

The supplied ZIP exceeded the transfer tool's 32 MiB limit and was not read. A shallow Git clone of the supplied URL was successfully inspected instead. These are not asserted to be identical snapshots. The reference checkout is separate from the game at `/workspace/references/gt4-decomp-upstream`; no original reference files were modified or bundled into the game. At this commit the source tree contains 30,207 C/C++ files and 27 knowledge documents.

## Evidence and application

| Reference path at the pinned commit | Observed content | Use in Evolution |
| --- | --- | --- |
| `src/race/unit_0034E9A0/func_00363868.cpp` | Speed multiplied by an indexed transmission ratio; conversion of angular speed to RPM using `60 / (2*pi)`; lower/upper bounds | Replace the provisional repeating speed-band RPM display with explicit wheel/gear/final-drive parameters |
| `src/race/unit_0034E9A0/func_00351DC8.cpp` | Current gear moves toward a requested gear one step at a time; state checks and unresolved callees | Sequential automatic gear changes in a new independent implementation; Evolution adds its own cooldown and hysteresis |
| `src/race/unit_0034E9A0/func_00360520.cpp` | Candidate road speeds, gearing, RPM, engine-output and resistance calculations | Future engine/drag model research; not ported or reproduced |
| `src/race/unit_0034E9A0/DynamicsConductor__ProcessCheckPoint.c` | Constructs a display event through unresolved calls | Does not establish checkpoint validation rules; not used as a lap-validation implementation |
| `src/race/RaceLapTime/RaceLapTime__structor_0.c` | Initializes fields and a 1,000-element table to a sentinel | Not enough evidence for persistence semantics or time units; not ported |
| `include/gt4/VehicleModel.h`, `include/gt4/RaceCarModel.h` | Generated virtual interfaces and partly unknown fields | Architectural reference only; not complete simulation models |
| `knowledge/architecture.md`, `knowledge/classes.md` | Maps race sessions, dynamics, data, HUD and inferred AI roles | Navigation guide, with inferred/unknown findings retained as such |
| `src/engine/EnemyLineProcessorOld/` | Located constructors/destructors, not a complete verified racing controller | Does not provide ready-to-use rival AI |

For a source link use `https://github.com/gustavocanepa/gt4-decomp/blob/122afce110f76738720f5c0dfdfc410c5d08a62e/<path>`.

## Implemented boundary

`scripts/transmission.gd` is new GDScript. Wheel angular speed is calculated as speed divided by configured rolling radius; engine angular speed multiplies the gear and final-drive ratios, then converts to RPM. Forward and reverse ratios, idle/redline and shift thresholds are configurable. Shift intervals and different up/down thresholds prevent repeated gear changes around a boundary. The preset values are provisional Evolution tuning, not extracted GT4 car specifications. Acceleration remains the existing arcade model; this is not a torque, clutch, differential or full drivetrain simulation.

No C/C++ source, executable, commercial textures, models, vehicle specifications or circuits were copied into the prototype. The reference repository's `orig/README.md` explicitly requires separately supplied game data. Its research documents can lag the recovered sources; coverage percentages are not treated as proof of current physics completeness. The original build was not run because the game executable is absent; no byte-match claim is made.

## Attribution

Research project: Gustavo Canepa and gt4-decomp contributors. Its root license is MIT, copyright 2026; third-party code has separate notices in `THIRD_PARTY.md` and `LICENSES/`. These notices must be checked for any future direct source reuse. This increment references observations and standard unit conversions, without importing third-party implementations.
