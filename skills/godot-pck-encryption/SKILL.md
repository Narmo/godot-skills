---
name: godot-pck-encryption
description: "PCK encryption for Godot 4.x exports: generate a 256-bit AES key, compile custom export templates with SCRIPT_AES256_ENCRYPTION_KEY (Linux, Windows, macOS, Android, iOS, Web), configure the preset Encryption tab with filters that match exported file names (.gdc, .scn, .ctex), export from the CLI with GODOT_SCRIPT_ENCRYPTION_KEY, verify templates and PCKs, and fix encrypted-PCK load errors. Use when encrypting a Godot game's PCK, building export templates with an encryption key, or debugging 'MD5 sum of the decrypted file does not match' errors."
license: MIT
compatibility:
  - godot-4.7
metadata:
  author: vl4dt
  version: 0.1.0
  tags:
    - godot
    - export
    - encryption
    - pck
    - export-templates
    - scons
    - security
  created: 2026-11-19
---

# Godot PCK Encryption (Custom Export Templates)

Godot can AES-256 encrypt files inside the exported PCK. The game decrypts them with a key
**compiled into the export template**, so encryption only works with templates you build from
source with your key. The official templates carry an all-zero key and can never read your PCK.

Verified against Godot 4.7.2 source and headless test exports. Upstream page:
<https://docs.godotengine.org/en/4.7/engine_details/development/compiling/compiling_with_script_encryption_key.html>

## What It Protects — and What Not

- **Encrypted:** files matched by the include filters, plus the PCK index (paths, sizes) when
  *Encrypt Index* is on.
- **Not secret:** the key. It sits as 32 raw bytes in every shipped binary, and public tools
  locate it. This stops casual PCK unpacking, not a determined reverse engineer.
- **Never covered** — anything outside the PCK:
  - GDExtension libraries (shipped next to the executable).
  - C# assemblies, unless they are embedded: they go into the PCK only on Android or with the
    `dotnet/embed_build_outputs` preset option (never on macOS). Otherwise they ship
    unencrypted in `data_<Project>_<platform>_<arch>/`.
  - Web builds: every visitor downloads the `.wasm` holding the key — encryption there is
    cosmetic.
- A keyed template still runs unencrypted PCKs (encryption is a per-file flag), but every game
  exported with it ships your key. **One key per game, one template set per key.**

## Golden Rules

1. **Two variables, one value.** `SCRIPT_AES256_ENCRYPTION_KEY` at **build** time bakes the key
   into the templates; `GODOT_SCRIPT_ENCRYPTION_KEY` at **export** time encrypts the PCK (it
   overrides the key saved in the preset). Different values → the game does not start.
2. **Every SCons run needs the variable.** A run without it silently compiles the all-zero key
   — one forgotten arch of a multi-arch template breaks only that hardware.
3. **Build from the editor's exact tag.** `4.7.2.stable.official` → `4.7.2-stable`.
4. **Filters match exported names, not source names.** `*.gd` and `*.tscn` encrypt *nothing*
   with default settings. Use `*` (see §5).
5. **The key never reaches git, logs, or shell history.** Always load it from a file or secret.

## 1. Generate and Store the Key

```sh
mkdir -p ~/.secrets && umask 077
openssl rand -hex 32 > ~/.secrets/mygame.gdkey     # 64 hex characters
```

- Keep the file outside the project. If it must live inside, add `*.gdkey` to `.gitignore`.
- Do not use the online generator the upstream page links — a third party saw the key.
- Never use `000…0`: that is the key the official templates already contain, so the stock
  engine decrypts such a PCK (verified: a zero-key PCK runs on the stock editor binary).
- CI: one secret, exposed under both variable names.
- A key typed into the editor's Encryption tab is saved **in plain text** to
  `.godot/export_credentials.cfg` (`script_encryption_key` under `[preset.N]`). `.godot/` must
  stay git-ignored. Prefer leaving the field empty and using the export variable.

## 2. Get Matching Engine Source

```sh
godot --version                    # 4.7.2.stable.official.ed1daf0bf
git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot.git godot-src
cd godot-src
```

A template older than the editor rejects the pack (`Pack created with a newer version of the
engine`). Toolchain prerequisites (Python, SCons, compilers, Android SDK/NDK, Xcode, Emscripten)
are in the upstream *Compiling for <platform>* pages; this skill assumes they are installed.

## 3. Build Templates With the Key

Load the key into the shell that runs SCons:

```sh
export SCRIPT_AES256_ENCRYPTION_KEY="$(cat ~/.secrets/mygame.gdkey)"      # Linux / macOS
```

```powershell
$env:SCRIPT_AES256_ENCRYPTION_KEY = (Get-Content $HOME\.secrets\mygame.gdkey -Raw).Trim()
```

```bat
:: Windows cmd — reads the first line of the file
set /p SCRIPT_AES256_ENCRYPTION_KEY=<%USERPROFILE%\.secrets\mygame.gdkey
```

Every SCons run must start with this banner; no banner means that build got the zero key:

```text
*** IMPORTANT: Compiling Godot with custom `SCRIPT_AES256_ENCRYPTION_KEY` set as environment variable.
*** Make sure to use templates compiled with this key when exporting a project with encryption.
```

A malformed key stops the build: `Invalid AES256 encryption key, not 64 hexadecimal characters`.

Commands per platform (from the 4.7 compiling pages; skip the debug template if you never
export debug builds; add `production=yes` to release builds — static C++ runtime, LTO where
supported, `debug_symbols=no`):

```sh
# Linux → bin/godot.linuxbsd.template_{release,debug}.x86_64
scons platform=linuxbsd target=template_release arch=x86_64 production=yes
scons platform=linuxbsd target=template_debug arch=x86_64

# Windows → bin/godot.windows.template_{release,debug}.x86_64.exe
scons platform=windows target=template_release arch=x86_64 production=yes
scons platform=windows target=template_debug arch=x86_64

# macOS Universal 2 → bin/godot_macos.zip (generate_bundle on the LAST command runs lipo + zip)
scons platform=macos target=template_debug arch=arm64
scons platform=macos target=template_release arch=arm64
scons platform=macos target=template_debug arch=x86_64
scons platform=macos target=template_release arch=x86_64 generate_bundle=yes

# Android → bin/android_release.apk, bin/android_debug.apk, bin/android_source.zip
# (generate_android_binaries on the last arch of each target)
scons platform=android target=template_release arch=arm32
scons platform=android target=template_release arch=arm64 generate_android_binaries=yes
scons platform=android target=template_debug arch=arm32
scons platform=android target=template_debug arch=arm64 generate_android_binaries=yes

# iOS → bin/godot_ios.zip
scons platform=ios target=template_debug generate_bundle=yes
scons platform=ios target=template_release generate_bundle=yes

# Web → bin/godot.web.template_{release,debug}.wasm32.zip (see the Web caveat above)
scons platform=web target=template_release
scons platform=web target=template_debug
```

- **Key changes are cheap.** SCons tracks the key's value: a new key regenerates
  `core/script_encryption_key.gen.cpp`, recompiles that one file, and relinks. No clean build.
- **Keep `debug_symbols=no`** (the default) for shipped templates. The linker then strips the
  symbol table; with symbols, `script_encryption_key` names the exact address of the key.
- **SCons cache** (`cache_path=`): the generated key source is excluded from the cache, the
  object compiled from it is not. Do not share that cache with other projects or untrusted jobs.

## 4. Check the Templates Before Using Them

```sh
KEYFILE=~/.secrets/mygame.gdkey
BIN=bin/godot.linuxbsd.template_release.x86_64
# The key is baked in (prints a verdict, never the key):
python3 -c 'import sys; k=bytes.fromhex(open(sys.argv[1]).read().strip()); print("key present" if k in open(sys.argv[2],"rb").read() else "KEY MISSING")' "$KEYFILE" "$BIN"
# No symbol points at it — must print nothing ("no symbols" is fine):
nm "$BIN" 2>&1 | grep script_encryption_key
```

- Check **every arch binary**: `bin/godot.macos.template_release.arm64` and `.x86_64` before
  bundling, both Android ABIs.
- Zips and APKs are compressed — unpack first. Android:
  `unzip -o bin/android_release.apk 'lib/*' -d /tmp/apk`, then check each
  `lib/<abi>/libgodot_android.so`, also with `nm -D`.
- iOS ships a static library, which must keep the symbol for linking. Check the binary inside
  the archived `.app` instead.
- Reference point: the official 4.7.2 Linux, Windows, macOS and Android templates have no
  `script_encryption_key` symbol.

## 5. Configure the Export Preset

Editor: **Project → Export → preset → Encryption** tab — *Encrypt Exported PCK*,
*Encrypt Index (File Names and Info)*, *Include Filters*, *Exclude Filters*, *Encryption Key*.
Point **Options → Custom Template** at your templates.

By hand in `export_presets.cfg` — encryption keys sit in `[preset.N]`, templates in
`[preset.N.options]`:

```ini
[preset.0]
name="Linux"
platform="Linux"
encryption_include_filters="*"
encryption_exclude_filters=""
seed=0
encrypt_pck=true
encrypt_directory=true

[preset.0.options]
custom_template/debug="/opt/godot-src/bin/godot.linuxbsd.template_debug.x86_64"
custom_template/release="/opt/godot-src/bin/godot.linuxbsd.template_release.x86_64"
```

| Platform | Preset option | File |
|---|---|---|
| Linux, Windows | `custom_template/release`, `custom_template/debug` | the binaries from `bin/` |
| macOS | same | `godot_macos.zip` |
| iOS | same | `godot_ios.zip` |
| Web | same | `godot.web.template_*.wasm32.zip` |
| Android | same | `android_release.apk`, `android_debug.apk` |
| Android, Gradle build | `gradle_build/android_source_template` | `android_source.zip` |

- Template paths are absolute and the presets file is usually committed: keep the source tree
  at the same path on every machine, or (on a runner that builds only this game) copy the files
  into `export_templates/<version>/` under the official names (`linux_release.x86_64`,
  `windows_release_x86_64.exe`, `macos.zip`, `ios.zip`, `android_source.zip`, `web_release.zip`, …).
  That replaces the official templates for **every** project on the machine.
- `seed=0` → random IVs on every export. A non-zero seed derives IVs from the seed and file
  contents → byte-reproducible PCKs.

### Filters match the names stored in the PCK

Filters are comma-separated, case-insensitive globs tested against each stored path with and
without `res://`; `*` also crosses `/`. Exclude wins over include. What 4.7.2 stores by default:

| Source file | Stored in the PCK as |
|---|---|
| `player.gd` | `player.gdc` (binary tokens, the default script export mode) + `player.gd.remap` |
| `level.tscn` | `.godot/exported/<hash>/export-<md5>-level.scn` + `level.tscn.remap` (`editor/export/convert_text_resources_to_binary`, on by default) |
| `icon.png` (any imported file) | `.godot/imported/icon.png-<md5>.ctex` + `icon.png.import` |
| `project.godot` | `project.binary` |

So `*.gd`, `*.tscn` — and the editor's own hint `*.tscn, *.tres, scenes/*` — miss the real
data: a test export filtered on `*.gd` came out byte-identical to an unencrypted one. Folder
filters like `scenes/*` catch the `.remap` stubs and `.gdc` scripts but not converted scenes
or imported assets, which live under `.godot/`.

**Use `encryption_include_filters="*"` with `encrypt_directory=true`.** Exclude only large
streamed media: an encrypted file is decrypted *whole* into memory when opened, so streaming is
lost — e.g. `encryption_exclude_filters="*.oggvorbisstr,videos/*"` (imported OGG music is
stored as `.oggvorbisstr`).

## 6. Export

```sh
export GODOT_SCRIPT_ENCRYPTION_KEY="$(cat ~/.secrets/mygame.gdkey)"
godot --headless --path . --export-release "Linux" builds/linux/game.x86_64
```

- No key at export, or one that is not 64 characters → export fails with exit 1 and
  `Condition "p_key.size() != 32" is true`.
- Export does **not** validate hex digits: a typo yields a wrong key silently and the game fails
  at runtime. Reading both variables from the same file avoids it (SCons does validate).
- **Android Gradle build:** the engine library comes from `res://android/build`, copied there
  when the build template is installed. After rebuilding templates (new key or version), delete
  `android/build` and install it again — editor *Project → Install Android Build Template*, or
  `--install-android-build-template` on the export command (it uses
  `gradle_build/android_source_template` when set). Re-apply any manual edits you made there.

## 7. Verify the Export

With a separate `.pck` (`binary_format/embed_pck` off):

```sh
# 1. The stock editor (zero key) must FAIL to load it:
godot --headless --main-pack builds/linux/game.pck
#    expected: "The MD5 sum of the decrypted file does not match ..." or
#    "Can't open encrypted pack directory." — if the game runs instead, nothing was
#    encrypted or the zero key was used
# 2. A unique scene string (node name, label text) must not appear in plain text:
grep -a -c 'SomeUniqueNodeName' builds/linux/game.pck     # 0
# 3. The real export must start normally on target hardware.
```

Grep a scene string, not a script identifier: compressed binary tokens hide identifiers even
in an unencrypted PCK, so a script check proves nothing.

## Troubleshooting

| Symptom (4.7.2 wording) | Cause | Fix |
|---|---|---|
| `The MD5 sum of the decrypted file does not match the expected value...` at `open_and_parse (core/io/file_access_encrypted.cpp:113)`, then `Can't open encrypted pack-referenced file "res://project.binary"` | Template key ≠ export key | Official template still selected, an arch built without the variable, stale `android/build`, or a typo in `GODOT_SCRIPT_ENCRYPTION_KEY`. Run §4 on the template actually used |
| `Can't open encrypted pack directory.` | Same, with *Encrypt Index* on | Same |
| Export exits 1: `Condition "p_key.size() != 32" is true` | Encryption on, no valid key at export | Set `GODOT_SCRIPT_ENCRYPTION_KEY` (or the preset's key field) |
| SCons: `Invalid AES256 encryption key, not 64 hexadecimal characters` | Bad build variable | Load it from the key file; no quotes or spaces inside |
| `Pack created with a newer version of the engine` | Templates built from an older tag | Rebuild from the tag matching `godot --version` |
| Game runs, but data is readable in the PCK | Filters written for source names | `*` (§5) |
| Encrypted music or video eats memory | Whole-file decryption on open | Exclude streamed media |

The upstream page still quotes the older message
(`Condition "String::md5(md5.digest) != String::md5(md5d)" is true`); 4.7 prints the MD5 text
above.

## Key Rotation and Patches

- New key → rebuild every template (one file recompiles), re-export every platform. Builds
  already shipped keep working with their old key.
- A shipped binary has exactly one key for **all** packs it loads: patch PCKs and DLC loaded
  with `ProjectSettings.load_resource_pack()` must be encrypted with the same key as that build.

## Related Skills

- `godot-headless-workflow` — CLI export loop, presets, Android signing variables.
- `godot-debugging` — general export/build troubleshooting.
