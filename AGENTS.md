# Instructions for agents in this repository

Matching decompilation of Gran Turismo 4 (`CORE.GT4`, PS2, ee-gcc 2.96 `-O2 -G0` C++; Sony SDK code
is ee-gcc 2.9 C). A function is done only when `python3 tools/swarm.py try` prints `MATCH`.

If your prompt starts with `Matcher worker`, the rest of this file is your whole job. Otherwise
read CLAUDE.md first.

## Source quality

Matching and readability are both acceptance criteria. Recovered code should be
understandable and maintainable by someone who has not read the original assembly.

- Prefer descriptive types, fields, parameters and locals. Use recovered original
  names only when supported by evidence; document provisional layouts and unknowns.
- Explain ownership, lifetimes, algorithm intent and non-obvious ABI constraints.
  Comments should explain decisions, rather than narrate individual instructions.
- Reuse the original public library algorithms where available, with provenance.
  Keep address mappings distinct from the code expressing the algorithm's behavior.
- Do not sacrifice a natural source model for a numerical match: no artificial
  dead stores, pinned registers or opaque instruction-shaped rewrites.
- Review the source and its callers/callees before counting a match. A successful
  compiler run or judge result alone does not establish source quality. Rejudge
  any cleanup and verify the complete link before claiming recovered bytes.
- Improve the family being worked on; defer unrelated legacy cleanup to its own
  reviewed change. Keep uncertain findings explicit for later contributors.

## Upstream contributions

Keep each PR focused on a meaningful family or subsystem milestone, with readable
sources, reproduction notes and complete-build evidence. Refresh upstream before
selecting targets and before submitting a PR. If upstream has recovered the same
function, preserve its implementation and revalidate the remaining local work.

## Matcher worker

Your prompt gives a worker name `W`, a tries budget and a batch: a JSON object with function
addresses leased to you. Match as many as you can, quickly, then report. Run every command from the
repository root. Other workers run in parallel on other functions; they never touch yours.

### Start

1. `python3 tools/swarm.py rules`: the compiler's habits and this game's idioms. Read it once.
2. `mkdir -p build/swarm/W` (your only scratch directory).

### Per function, in the order given

1. `python3 tools/swarm.py prompt ADDR`. It carries the original assembly, an automatic draft,
   solved similar functions, callees with their real prototypes, and three things to start from
   rather than rediscover:
   - **Translation-unit context** (predicted from the matched code, right about 9 times in 10): the
     first-line compiler marker to write and which callee prototypes get `throw()`. Use it as
     given; change it only when a diff says so.
   - **Retry report**, when an earlier draft was kept: the draft file to start from, what still
     differs, and what has already been tried (do not repeat it). When it says the draft's logic is
     certified, do not rewrite the logic: only the named compiler decision is left.
   - Notes of earlier attempts.
   Before writing, look for matched neighbours with the same shape (`ls src/*/UNIT/`, the similar
   functions in the prompt): many functions are a solved sibling with other constants.
2. Write a complete translation unit to `build/swarm/W/ADDR.cpp` (lower-case address, 8 digits).
   If the prompt says the function is built by the SDK compiler, write plain C to
   `build/swarm/W/ADDR.c` with the first line `/* compiler: ee-gcc2.9-991111 */`. Define the
   function as `func_ADDR` (upper-case hex), whatever its real name.
3. `python3 tools/swarm.py try ADDR build/swarm/W/ADDR.cpp --worker W`.
   - `MATCH: saved src/...`: done, the tool saved it (a `note:` line says when the tool closed it by
     applying the predicted context). Next function.
   - Otherwise read the diff (`!` marks differing rows, left is the original). The count is row by
     row: one inserted instruction shifts every later row, so judge closeness by what really
     differs.
4. On a near miss, try the cheap changes first, one at a time, before rewriting code:
   - a callee's declared return type flipped between `void` and a value (`int`, or `void *` for a
     constructor-like callee): it moves instructions around the call and the `$v0`/`$v1` choice;
   - a callee's prototype shortened to the arguments the original sets, or a float parameter moved
     earlier or later in it;
   - `throw()` added to or removed from ONE callee prototype at a time (callees at lower addresses
     in the same unit and C library functions are the candidates), when a branch and its
     branch-likely form (`beq`/`beql`) or a delay slot differ;
   - the function's own return type `void` to `int` with the body unchanged, when only the last
     stores or the epilogue's register restores are in the wrong order;
   - the first-line markers `/* compiler: ee-gcc2.96-no-strict-aliasing */`,
     `/* compiler: ee-gcc2.96-nsa-nosib */`, `/* compiler: ee-gcc2.96-nosib */`,
     `/* compiler: ee-gcc2.96-stl */`, `/* compiler: ee-gcc2.96-nogcse */` for a reload, a
     load/store order, stack-slot sharing, a sibling call or a merged subexpression. Never the
     `nosched1` profiles.
   Then change the source structurally: statement order, types and signedness, temporaries and
   where they are declared, loop shape, early returns against one exit, a `switch` against an if
   chain, an inline helper. Do not repeat a form that already failed.
5. Never mark a function `not attempted` because earlier tiers failed on it or because it looks large: make at least 3 real tries on its closest kept draft first (`swarm.py prompt` names it). Earlier tiers' notes are leads, not verdicts.
   Budget: the tries given in your prompt, every `try` run counted (reruns and compile failures
   too). Stop early and give up when a draft is stuck on register numbering or instruction order
   only after 4 tries (a mechanical tool and a stronger tier work those), or still more than a
   third of the function away after 3. When your prompt says `Whole budget`, you are the last
   tier and neither early stop applies: keep going while tries remain, and on a difference of
   a few instructions work out which source form makes the compiler take that decision (operand
   order, where a temporary is declared, an inline helper taking a value or a pointer, a
   narrower or wider type) rather than stopping. A "function" that is a fragment of a larger
   routine (uses the caller's saved registers, jumps into neighbouring code) gets no tries.
   Give up with: copy your closest draft to `build/swarm/W/ADDR_best.cpp` (or `.c`), then
   `python3 tools/swarm.py giveup ADDR TRIES --best N --note "what blocks it" --worker W`
   (N = fewest really differing instructions you reached), once per function.

### Never

- Edit anything outside `build/swarm/W/` (the `try` command alone writes `src/`).
- Run `tools/build.py`, `tools/organize.py`, `tools/dedup_all.py`, `git`, or `swarm.py assign` /
  `release`; edit `knowledge/`, `config/` or any tracked file.
- Use file-scope asm, `.word`, or multi-instruction inline asm (`try` rejects them). A single
  instruction the compiler cannot express (`sqrt.s`, `min.s`) may be inline asm.
- Work on addresses that are not in your batch.
- Script loops of `try` runs or brute-force permutations. Every command must end on its own: no
  command that waits on input, no background jobs.
- Prefer the natural source form; do not wrap code in `do { } while (0)` to move an instruction.

### Report

Your final message is the report and nothing else, in the JSON shape you were given: one entry per
function of the batch (`addr`, `result`: `match` or `deferred` or `fragment`, `tries`, `best`:
fewest differing instructions reached or 0 for a match, `note`: one line on what closed it or what
blocks it), and `lessons`: at most three one-line compiler rules you confirmed that
`swarm.py rules` did not state (an empty list when none).
