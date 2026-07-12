# Miruro API

Reverse-engineered anime streaming API (FastAPI / Python 3.12).  
Wraps AniList (metadata) and the Miruro pipe (episode sources + stream URLs).

---

## Running on Replit

The workflow **Start application** runs `bash start.sh`, which:

1. Builds `LD_LIBRARY_PATH` from the NixOS Nix store paths where the installed
   Chromium system libraries live (glib, nss, nspr, mesa, X11, etc.).
2. Starts `uvicorn api:app --host 0.0.0.0 --port ${PORT:-5000}`.

On **first boot** FastAPI's startup event fires, which opens a persistent
ViperTLS session and runs a one-time Cloudflare challenge solve via headless
Chromium (~30–60 s). Every subsequent pipe request reuses the same session and
cookie — no browser is spawned again until the cookie expires (1–24 h).

If you reinstall system packages via Replit's package manager the Nix store
hashes in `start.sh` will change — re-run the NixOS lib-path discovery steps
documented in `.agents/memory/nixos-chromium-libs.md`.

---

## Deploying elsewhere

### Railway / Render (recommended)
Use the included `Dockerfile`. Both platforms detect it automatically.

```
railway up          # or connect the GitHub repo in the Railway dashboard
```

On Ubuntu/Debian containers `playwright install-deps` handles all system libs —
the NixOS `LD_LIBRARY_PATH` dance in `start.sh` is not needed.

`railway.toml` and `render.yaml` are committed for one-click deploys.

### Vercel / serverless
❌ Not supported — the persistent ViperTLS session and Chromium binary require a
long-running process. Use Railway or Render instead.

---

## Cloudflare bypass — how it works

| Layer | Tool | What it does |
|---|---|---|
| TLS fingerprint | ViperTLS | Spoofs JA3/JA4 + HTTP/2 frame order to look like Chrome 145 |
| JS challenge | ViperTLS (Chromium) | Headless browser solves the challenge, caches `cf_clearance` |
| Cookie reuse | Persistent session | One `AsyncClient` lives for the server lifetime; cookie reused for every request |
| Cookie expiry | Auto re-solve | On 403, re-warms under a lock; other requests queue and retry |

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/` | API reference (HTML) |
| GET | `/search?query=&page=&per_page=` | Search anime via AniList |
| GET | `/info/{anilistId}` | Full anime metadata |
| GET | `/trending` | Trending anime |
| GET | `/popular` | Popular anime |
| GET | `/upcoming` | Upcoming anime |
| GET | `/anime/{anilistId}/recommendations` | Recommendations |
| GET | `/episodes/{anilistId}` | Episode list + provider slugs |
| GET | `/watch/{provider}/{anilistId}/{sub\|dub}/{episodeId}` | Stream URLs |

---

## User preferences

- Keep the persistent ViperTLS session pattern — never revert to per-request `async with` clients.
- `start.sh` is the Replit entrypoint; `Dockerfile` is for cloud deploys.
