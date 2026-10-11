# TBD 3den Tools

Eden Editor extension for mission optimization and composition management.

## Features

### Custom Simple Objects (CSO)
Converts objects into Simple Objects to improve frame rates.
*   **Mass conversion**: Can handle thousands of objects.
*   **Attributes**:
    *   **Align to Terrain**: Aligns objects to the terrain normal.
    *   **Force Super Simple**: Removes all physics (visual only) for maximum performance. When disabled, basic collision is kept.
*   **Non-Destructive**: Objects can be restored to their original state.

### Global Library
A persistent library for saving compositions between missions.
*   **Backend**: Uses a Rust-based SQLite extension for storage.
*   **Positioning**: Saves the absolute position of objects, which allows for precise placement compared to vanilla.
*   **Organization**: Supports folders and search.

### Development Utilities
*   **Clipboard**: Export object data to arrays for scripts.
*   **Logic Spawner**: Creates a Game Logic to spawn compositions at mission start.

> **Note**: This mod uses the `TBD_DB_x64.dll` extension. It sets up the database automatically.

## Usage

### Optimization
1.  Select objects in Eden.
2.  Check **"Create as simple object?"** in Object Attributes.
3.  Use the **TBD Tools** menu in the Eden menu bar: **TBD Tools > CSO Operations**.

### Library
1.  Open **TBD Tools > TBD Global Library (Saved Groups)**.
2.  **Save**: Select objects, enter a name, and save.
3.  **Load**: Select an item and load it.

## Repository Layout

| Path | Contents |
|------|----------|
| `addons/TBD_3den_Tools` | SQF addon source (config, functions, UI) |
| `extension` | Rust source of the `TBD_DB_x64.dll` SQLite extension |
| `.hemtt` | Mod packaging configuration and hooks |
| `Cargo.toml`, `Cargo.lock` | Root Cargo workspace and shared dependency lockfile |
| `.hemttout/build` | Generated local mod package (gitignored) |
| `target` | Generated Rust build output (gitignored) |

## Building from Source

### Complete Windows Build

Install [Rust](https://rustup.rs/) with the 64-bit Windows MSVC toolchain and
Visual Studio C++ Build Tools, plus [HEMTT](https://hemtt.dev/) on `PATH`.
CI uses HEMTT **1.19.1**. From the repository root, run:

```bat
build.bat
```

The script also works when launched from another directory. It builds the
extension with `cargo build --release --locked`, stages
`target/release/TBD_DB_x64.dll` at the repository root, and runs `hemtt build`.
Any failure stops the build and returns a nonzero exit code.

The complete local mod is written directly to **`.hemttout/build/`**:

```text
.hemttout/build/
├── addons/
│   └── TBD_3den_Tools_TBD_3den_Tools.pbo
├── TBD_DB_x64.dll
├── mod.cpp
├── README.md
├── LICENSE.md
└── AUTHORS.txt
```

HEMTT rapifies `config.cpp`, binarizes the stringtable, and compiles SQF to
`.sqfc`. The DLL belongs alongside `mod.cpp` at the mod root; it is excluded
from PBOs. Direct `hemtt build` requires an already-built Windows DLL staged
at the repository root. The post-build hook rejects packages missing it.

### Linux Cross-Compilation

Install Rust, HEMTT, and a MinGW-w64 compiler providing
`x86_64-w64-mingw32-gcc` and `x86_64-w64-mingw32-ar` on `PATH`. The bundled
SQLite dependency also needs this C toolchain. From the repository root:

```sh
rustup target add x86_64-pc-windows-gnu
CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc \
AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-ar \
cargo build --release --locked --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/TBD_DB_x64.dll TBD_DB_x64.dll
hemtt build
```

A native Linux Cargo build produces a shared library rather than the Windows
DLL required by this package.

### Checks and CI

Run the checks from the repository root:

```sh
cargo test --locked
cargo clippy --locked --all-targets -- -D warnings
hemtt check
```

The CI workflow (`.github/workflows/ci.yml`) runs on every push and pull
request and can be started manually. It tests and lints the Rust workspace on
Linux, then builds the complete mod on Windows and uploads a downloadable
`TBD_3den_Tools` artifact containing an `@TBD_3den_Tools` folder. It does not
publish a GitHub Release. Generated packages and binaries are gitignored.

## Installation

Download and extract the CI workflow's `TBD_3den_Tools` artifact, or copy the contents of
`.hemttout/build/` into a local `@TBD_3den_Tools` folder. Add that folder to the
Arma 3 launcher as a local mod and enable it. Keep `TBD_DB_x64.dll` at the mod
root alongside `mod.cpp` and the `addons` directory. If Windows blocks the DLL,
right-click it, open **Properties**, and select **Unblock** if available.

## Credits

*   **Author**: Darkforce
*   **Coding Help**: Antigravity
*   **License**: [APL-SA](LICENSE.md)
