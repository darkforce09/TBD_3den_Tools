# TBD 3den Tools

An Arma 3 Eden editor mod for mission makers of the TBD community. The SQF addon (`addons/TBD_3den_Tools`) converts placed objects into simple objects ("CSO", Custom Simple Objects) and keeps a global composition library across missions. The library is stored by a Rust SQLite extension (`extension/`, built as `TBD_DB_x64.dll`) that Arma loads through `callExtension`. HEMTT packs the mod; CI builds the complete Windows mod as an artifact.

---

## 1. Core Project Laws

The project is maintained by AI agents. Keep it small: every rule below states an outcome, and anything that serves no outcome is deleted rather than documented.

1. **No silent deferrals.** Do the whole ask. Never invent "out of scope", "deferred" or ship an MVP and call the task done. Only Sam's explicit words defer a piece; record it in the roadmap checklist. Truly blocked: stop and ask.
2. **Git: direct to `main`.** For parallel work use a worktree: `git worktree add .worktrees/<name> -b <name>`, merge it into `main`, then `git worktree remove .worktrees/<name>` and delete the branch. No other branches. Commit only when asked.
3. **Everything earns its place.** A module, command, check, test, README or document exists only if something uses it: CI, a runbook step, or a reader who needs it. Investigations and probes live in `.workstation/` and are deleted with their task; they never become commands. Delete dead code instead of explaining it. When the clean fix needs a refactor, do the refactor.
4. **Boundaries.** Saved missions must keep loading: the `CfgPatches` class `TBD_3den_Tools`, the addon prefix and the Eden attribute classes `CSObject`, `CSO_Align`, `CSO_Super`, `CSO_Local` (`addons/TBD_3den_Tools/config.cpp`) are written into players' `mission.sqm` files and are never renamed, even though HEMTT warns that the addon name is not lowercase. The extension's `callExtension` command names and the SQLite schema are read by `addons/TBD_3den_Tools/functions/library/fn_database.sqf` and by players' existing `TBD_DB.db` files. The DLL sits at the mod root next to `mod.cpp`, never inside a PBO (`.hemtt/project.toml` excludes it from PBOs; the post-build hook copies it and fails the build when it is missing). Built binaries (`*.dll`, `*.pbo`) are never committed; the CI artifact is the distribution.
5. **Names and comments say what things are now.** Self-describing names, no abbreviations or history. Comments explain what and why (invariants, constraints, failure modes), never history, ticket ids or retired code. `///` docs on public Rust items. SQF functions keep their standard header block.
6. **Documentation is small and true.** One `README.md`, shipped inside the mod for players and developers: features, usage, build, install; no file-tree listings. Open work lives in a roadmap checklist in the README only while there is open work. When a change alters a menu, attribute, command or build step, update the README in the same commit.
7. **Tests cover core logic only.** The extension's chunked output math, UTF-8 boundaries, database reads and writes. Never pin prose, constants or `Debug`/`Display` output; no property or failpoint suites. The tests sit in the `mod tests` block of `extension/src/lib.rs`: the crate is cdylib-only, so a `tests/` folder would need an extra library target just for tests.
8. **CI is the law.** Every rule with a checker runs in CI (`.github/workflows/ci.yml`); a check not in CI is deleted. Gates pin their tools: Rust in `rust-toolchain.toml`, HEMTT by version in the workflow. A gate that cannot run is a bug to fix, never a skip. Before committing: `cargo fmt --all --check`, `cargo clippy`, `cargo test` and `hemtt check`.
9. **Everything stays in the repository.** Nothing project-related goes to `~`, `~/.cache` or `/tmp`: machine state in the gitignored `.workstation/` (logs in `.workstation/logs/`), worktrees in `.worktrees/`, build output in `target/` and `.hemttout/`.

---

## 2. Agent Environment and Workflow

- **Build:** Rust pinned by `rust-toolchain.toml` (with the `x86_64-pc-windows-gnu` target), one `target/`. HEMTT 1.19.1 (`~/.local/bin/hemtt`) packs the mod into `.hemttout/build/`. On Linux the Windows DLL is cross-compiled with MinGW-w64 (README, "Linux Cross-Compilation"); a native Linux build produces a `.so` that Arma cannot load. In-game testing needs Arma 3 on Windows or Proton and is Sam's.
- **Machine-local state** (`.workstation/`, gitignored): `logs/`, investigation notes.
- **Tracker:** a roadmap checklist in `README.md` when there is open work; none today.
- **Orchestration is opt-in.** Work in the chat by default; sub-agents only for broad searches or genuinely parallel pieces; multi-agent programs only when Sam asks.
- **Bash discipline.** One build, test or gate per Bash call, each with its own log under `.workstation/logs/`; read logs and large files in ranges.

---

## 3. Repository Map

| Folder | Holds |
|---|---|
| `addons/TBD_3den_Tools/` | The SQF addon: `config.cpp` (patches, Eden attributes, menus, function registry), `functions/` (core, cso, library), `ui/` dialogs, `Stringtable.xml` |
| `extension/` | The Rust SQLite extension crate, built as `TBD_DB_x64.dll` |
| `.hemtt/` | HEMTT project config and the post-build hook that places the DLL at the mod root |
| `.github/workflows/` | `ci.yml`: Rust checks on Linux, full mod package on Windows |
| `build.bat` | The Windows build: DLL, stage, `hemtt build` (CI entry point) |
| `.workstation/`, `.worktrees/`, `target/`, `.hemttout/` | Gitignored machine state, linked worktrees, build output |

---

## 4. Canonical Commands

```bash
cargo fmt --all --check                                     # Format gate
cargo clippy --workspace --all-targets --locked -- -D warnings  # Lint gate
cargo test --workspace --locked                             # Extension tests
hemtt check                                                 # SQF, config and stringtable lints
build.bat                                                   # Windows: complete mod in .hemttout/build/
```

Linux cross-build of the DLL and package: README, "Linux Cross-Compilation".
