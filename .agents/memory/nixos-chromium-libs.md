---
name: NixOS Chromium library paths
description: How to get Chromium running on Replit (NixOS) for ViperTLS / Playwright — LD_LIBRARY_PATH setup and the libgbm workaround.
---

# NixOS Chromium library paths for ViperTLS

## The problem
Playwright's downloaded Chromium binary links against standard Linux `.so` files
that don't exist at standard paths on NixOS. `ldd chrome` reports "not found"
for every library until you build `LD_LIBRARY_PATH` manually.

## Fix
1. Install the required Nix packages via `installSystemDependencies()`:
   `glib, nss, nspr, atk, at-spi2-atk, at-spi2-core, dbus, cups, libdrm, mesa,
   libxkbcommon, alsa-lib, expat, udev, pango, cairo, gtk3,
   xorg.libX11, xorg.libXcomposite, xorg.libXdamage, xorg.libXext,
   xorg.libXfixes, xorg.libXrandr, xorg.libxcb, xorg.libXcursor, xorg.libXi`

2. `libgbm.so.1` is **not** in the mesa Nix output on this Replit instance.
   It exists only inside `electronplayer-2.0.8-usr-target/lib`, but that dir
   also ships a conflicting `libc.so.6`. Symlink ONLY libgbm into a clean dir:
   ```
   mkdir -p vipertls/libs
   ln -sf /nix/store/<electronplayer-hash>/lib/libgbm.so.1 vipertls/libs/libgbm.so.1
   ln -sf vipertls/libs/libgbm.so.1 vipertls/libs/libgbm.so
   ```
   Add `vipertls/libs` to `LD_LIBRARY_PATH` (not the full electronplayer dir).

3. Get the Nix store paths via:
   ```bash
   nix-instantiate --eval -E "with import <nixpkgs> {}; <pkg>.outPath" | tr -d '"'
   ```

4. Set `LD_LIBRARY_PATH` in `start.sh` before launching uvicorn. The env var is
   inherited by child processes (Chromium) — setting it in Python `os.environ`
   after import also works for subprocesses.

**Why:** Nix stores each package under a content-addressed hash path; Chromium
binaries don't use `rpath` entries pointing there, so they can't find libs
without `LD_LIBRARY_PATH`.

**How to apply:** Any time Chromium/Playwright fails with "cannot open shared
object file" on Replit, re-run `ldd chrome | grep "not found"` with the new
LD_LIBRARY_PATH set, find the missing lib in `/nix/store`, and add its parent
dir (or a symlink) to `start.sh`.

**Note:** This is only needed on Replit (NixOS). On Railway/Render (Ubuntu),
`playwright install --with-deps chromium` handles all system libs automatically.
