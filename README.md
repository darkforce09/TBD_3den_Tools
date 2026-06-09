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
| `Source/Mod` | SQF addon source (config, functions, UI) |
| `Source/Extension/TBD_DB/TBD_DB_Rust` | Rust source of the `TBD_DB_x64.dll` SQLite extension |
| `Release/TBD_3den_Tools` | Packaged mod (PBO + DLL) ready to use |

## Building from Source

### Extension (`TBD_DB_x64.dll`)

Requires [Rust](https://rustup.rs/). The DLL must be built for Windows
(build on Windows, or cross-compile with the `x86_64-pc-windows-gnu` target):

```
cd Source/Extension/TBD_DB/TBD_DB_Rust
cargo test
cargo build --release
```

Copy the resulting `TBD_DB_x64.dll` to both shipped locations:

*   `Source/Mod/addons/TBD_3den_Tools/TBD_DB_x64.dll`
*   `Release/TBD_3den_Tools/TBD_DB_x64.dll`

### Mod (PBO)

The mod is built with [HEMTT](https://hemtt.dev/) (project config in
`Source/Mod/.hemtt/project.toml`):

```
cd Source/Mod
hemtt build
```

Copy the result to the release folder:

```
cp .hemttout/build/addons/TBD_3den_Tools_TBD_3den_Tools.pbo \
   ../../Release/TBD_3den_Tools/addons/TBD_3den_Tools.pbo
```

HEMTT binarizes `config.cpp` and the stringtable, compiles all SQF to
`.sqfc`, and excludes the DLL from the PBO (it is loaded from the mod root,
not from inside the PBO).

## Credits

*   **Author**: Darkforce
*   **Coding Help**: Antigravity
*   **License**: [APL-SA](LICENSE.md)
