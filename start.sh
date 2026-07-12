#!/usr/bin/env bash
# Sets LD_LIBRARY_PATH so the Chromium browser (used by ViperTLS for CF challenge
# solving) can find all its NixOS system library dependencies, then starts uvicorn.

NIX_LIBS=(
  /nix/store/3ybnl9nq86s7jz0i8pzqlrabjgdxzrjz-glib-2.84.3-bin/lib
  /nix/store/2jsrwgic869zynqljiqa4g7dqzpwm2yd-nss-3.101.2/lib
  /nix/store/gpb87pb8s826aggy1s3f352alp40dkj8-nspr-4.36/lib
  /nix/store/qrij2csr7p6jsfa40d7h4ckzqg4wd5w2-at-spi2-core-2.56.2/lib
  /nix/store/si92b84j9mqr3zshc8l78b7liq98sldc-cups-2.4.11/lib
  /nix/store/xpszkfp1gaf8jfmcsll93xg0pb4c0rk7-libdrm-2.4.124/lib
  /nix/store/jfpaxm9dvrrv3xsdbz5y3myj7sxkp7hj-pango-1.56.3-bin/lib
  /nix/store/prjwp9nyczsza4kga6a2bcb3qz1mvxg7-cairo-1.18.2/lib
  /nix/store/6x7s7vfydrik42pk4599sm1jcqxmi1qp-gtk+3-3.24.49/lib
  /nix/store/sisfq9wihyqqjzmrpik9b4xksifw97ha-libxkbcommon-1.8.1/lib
  /nix/store/yw5xqn8lqinrifm9ij80nrmf0i6fdcbx-alsa-lib-1.2.13/lib
  /nix/store/l0d83xf43lsyhzqziy0am1cidhkcxs9q-expat-2.7.1/lib
  /nix/store/5flwv7rri80114p8vlz7l8qf8z5i557h-systemd-minimal-libs-257.6/lib
  /nix/store/cpwib3zazj49fm0y04y53w4xkbqsgrgm-mesa-25.0.7/lib
  /nix/store/1nsvsrqp5zm96r9p3rrq3yhlyw8jiy91-libX11-1.8.12/lib
  /nix/store/4phl6z95v2i4525y0zpmi9v6ac0n4bx7-libXcomposite-0.4.6/lib
  /nix/store/2y2hhlki6macaj9j1409q1j6i33l6igf-libxcb-1.17.0/lib
  /nix/store/5fcbi2lycw2hz7rbn3nl5nrhhk2ki8dd-libXrandr-1.5.4/lib
  /nix/store/0046rn5sgi6l38zl81bg2r02zlzxqqbc-libXext-1.3.6/lib
  /nix/store/94grp8dx897wmf0x3azpdbgzj3krz7v5-libXfixes-6.0.1/lib
  /nix/store/h8143a07cf1vw41s49h0zahnq13zim94-libXdamage-1.1.6/lib
  # libgbm.so.1 symlinked here to avoid importing the whole electronplayer dir
  # (which carries a conflicting libc that breaks other tools)
  /home/runner/workspace/vipertls/libs
)

# Build colon-separated path string (skip dirs that don't exist)
EXTRA=""
for dir in "${NIX_LIBS[@]}"; do
  [ -d "$dir" ] && EXTRA="${EXTRA}${EXTRA:+:}${dir}"
done

export LD_LIBRARY_PATH="${EXTRA}${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH}"

exec uvicorn api:app --host 0.0.0.0 --port "${PORT:-5000}"
