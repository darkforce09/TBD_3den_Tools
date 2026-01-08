# CSO: Custom Simple Objects (V2)

**Optimize your Arma 3 scenarios with ease.**

CSO is a powerful Eden Editor extension that helps you convert complex compositions into **Simple Objects**, significantly improving mission performance (FPS) while retaining visual fidelity.

## Key Features

*   **🚀 Performance Boost**: Convert thousands of decorative objects into Simple Objects (no physics simulation) with a single click.
*   **📂 Global Library**: Save your compositions to a persistent database. Access your favorite layouts across *any* mission.
    *   **Folder Support**: Organize your library with unlimited folders (e.g., `Airports/Runways/Lights`).
*   **📋 Clipboard Tools**: Copy object data directly to your clipboard for use in scripts or config files.
*   **🧠 Logic Spawner**: Automatically generate a "Game Logic" entity that spawns your objects at mission start (Zero editor clutter).
*   **↩️ Restore & Edit**: Need to change something? Restore any CSO composition back to editable Eden objects instantly.

## Installation

1.  Subscribe on Steam Workshop OR copy the `@TBD_3den_Tools` folder to your Arma 3 directory.
2.  Enable the mod in the Arma 3 Launcher.
3.  **Requirement**: This mod creates a folder named `CSO_DB` in your Arma 3 root directory to store your library.

## How to Use

### 1. The Optimization Flow
1.  Place your objects in Eden Editor.
2.  Select them and check **"Create as simple object?"** in the Object Attributes (Custom Attributes section).
3.  *(Optional)* Customize settings:
    *   **Align to Terrain**: Useful for fences/walls on slopes.
    *   **Force Super Simple**: Removes ALL collision (visual only) for maximum performance.
4.  Open the **Tools** menu > **CSO Optimization Tools**.

### 2. The Global Library
Stop rebuilding the same base twice!
1.  Open **CSO Global Library**.
2.  **Save**: Select your objects, type a name (e.g., `Bunkers/North_Gate`), and click **Save Selected**.
3.  **New Folder**: Click [NEW FOLDER] to create organization categories.
4.  **Load**: Select an item from the tree and click **LOAD GROUP** to paste it into your mission.

### 3. Exporting to Scripts
1.  Open **Copy Code to Clipboard**.
2.  Click **COPY**.
3.  Paste into your `init.sqf` or trigger. The code is self-contained and includes the efficient spawner function!

## Credits

*   **Author**: Darkforce
*   **Version**: 2.0
*   **License**: APL-SA (Attribution-ShareAlike)
