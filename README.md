# TBD 3den Tools

Eden Editor extension for mission optimization and composition management.

## Features

### Custom Simple Objects (CSO)
Converts objects into Simple Objects to improve frame rates.
*   **Mass conversion**: Can handle thousands of objects.
*   **Attributes**:
    *   **Align to Terrain**: Aligns objects to the terrain normal.
    *   **Force Super Simple**: More frames, no texuring though
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
3.  Run **Tools > TBD Optimization Tools**.

### Library
1.  Open **Tools > TBD Global Library**.
2.  **Save**: Select objects, enter a name, and save.
3.  **Load**: Select an item and load it.

## Credits

*   **Author**: Darkforce
*   **Coding Help**: Antigravity
*   **License**: APL-SA
