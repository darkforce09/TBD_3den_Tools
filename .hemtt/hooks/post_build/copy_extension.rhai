if HEMTT.is_build() || HEMTT.is_release() {
    let source = HEMTT_RFS.join("TBD_DB_x64.dll");
    if !source.is_file() {
        fatal("TBD_DB_x64.dll is missing from the project root. Run build.bat, or build and stage the Windows DLL before running HEMTT.");
    }

    let destination = HEMTT_OUT.join("TBD_DB_x64.dll");
    if !source.copy(destination) {
        fatal("Failed to copy TBD_DB_x64.dll to the mod root.");
    }
    if !destination.is_file() {
        fatal("TBD_DB_x64.dll is missing from the built mod root.");
    }
    print("Windows extension included at the mod root.");
}
