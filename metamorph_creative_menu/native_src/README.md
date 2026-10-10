# Native Game Over recovery module

`mcm_native_gameover.c` builds the optional native bridge used by the standalone MCM build for the **I didn't die** Game Over recovery action.

The module is intentionally small and self-contained. It does not link the C runtime and does not import Lua or Win32 functions directly. At runtime it resolves the functions it needs from Noita's own PE import table.

## Target format

The shipped module is expected to remain:

- a **32-bit x86 PE DLL**;
- without a DLL entry point (`AddressOfEntryPoint = 0`);
- without a PE import table;
- with `luaopen_mcm_native_gameover` as its Lua module export;
- compatible with Noita's 32-bit process.

The scanner inside the module is adaptive: it locates supported Game Over structures from the running executable and fails closed when it cannot identify them safely. The build must not add hard-coded Noita virtual addresses or a CRT startup dependency.

## Building with MSVC

Use an **x86 Native Tools Command Prompt for Visual Studio** and run:

```bat
native_src\build_msvc.bat
```

The script compiles the C source and writes these files to the mod root:

- `mcm_native_gameover.dll` — runtime module shipped in the standalone/player build;
- `mcm_native_gameover.lib` — import library retained only in the full development source.

The intermediate object file is removed after a successful link.

## Verification

After rebuilding, run the normal MCM regression suite from the mod root:

```text
python tests/run_all.py .
```

For an additional PE-level check with Visual Studio tools:

```bat
dumpbin /headers mcm_native_gameover.dll
dumpbin /exports mcm_native_gameover.dll
dumpbin /imports mcm_native_gameover.dll
```

The DLL should report machine type x86, an entry point of zero, the `luaopen_mcm_native_gameover` export, and no imported DLLs.
