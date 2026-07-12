---
name: ViperTLS Cloudflare bypass for miruro.tv pipe
description: Proven strategy for getting past Cloudflare on miruro.tv/api/secure/pipe from a datacenter IP (Replit, Railway, Render).
---

# ViperTLS CF bypass — miruro.tv pipe

## The problem
`miruro.tv/api/secure/pipe` is behind Cloudflare. Replit/Railway/Render IPs are
datacenter-flagged, so plain `httpx` / `curl_cffi` TLS spoofing alone returns
403 "Attention Required!" (hard IP-reputation block, not a solvable challenge).

## Proven solution
Use **ViperTLS** (`pip install vipertls`) — by the same author as this project.

Two-step strategy that works from datacenter IPs:
1. Visit `https://www.miruro.tv/` with a ViperTLS AsyncClient (impersonate chrome_145).
   ViperTLS runs headless Chromium to solve the JS challenge → gets `cf_clearance` cookie.
2. Hit the pipe URL in the **same session** → Cloudflare passes it through (solved_by=cache).

## Persistent session (production pattern)
Do NOT create a new AsyncClient per request. One client lives for the server lifetime:

```python
_pipe_client = None
_warmup_lock = asyncio.Lock()

@app.on_event("startup")
async def _startup():
    global _pipe_client
    _pipe_client = vipertls.AsyncClient(impersonate="chrome_145", timeout=90, follow_redirects=True)
    await _pipe_client.get("https://www.miruro.tv/", headers=WARMUP_HEADERS)  # one-time solve

async def _pipe_get(url):
    r = await _pipe_client.get(url, headers=PIPE_HEADERS)
    if r.status_code == 403:
        async with _warmup_lock:          # only one re-solve at a time
            await _pipe_client.get("https://www.miruro.tv/", headers=WARMUP_HEADERS)
        r = await _pipe_client.get(url, headers=PIPE_HEADERS)
    ...
```

## Cookie lifetime
`cf_clearance` lasts 1–24 hours depending on Cloudflare config. ViperTLS also
caches it to disk in `$VIPERTLS_HOME/`, so server restarts reuse it if still valid.

## VIPERTLS_HOME must be set before import
When uvicorn is sys.argv[0], ViperTLS computes its home as `.pythonlibs/bin/vipertls`
(a file, not a dir) → FileExistsError on import. Fix:
```python
os.environ.setdefault("VIPERTLS_HOME", os.path.join(os.path.dirname(os.path.abspath(__file__)), "vipertls"))
import vipertls  # must come AFTER the setdefault
```

**Why:** ViperTLS reads VIPERTLS_HOME at import time to set up its directory structure.

## Deployment
- Replit (NixOS): needs LD_LIBRARY_PATH in start.sh (see nixos-chromium-libs.md)
- Railway/Render (Ubuntu Docker): `playwright install --with-deps chromium` + `vipertls install-browsers` in Dockerfile — no LD_LIBRARY_PATH needed.
- Vercel/serverless: ❌ not compatible (needs persistent process + 200MB Chromium binary).
