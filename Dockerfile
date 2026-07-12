FROM python:3.12-slim

# System deps Chromium needs on Debian/Ubuntu (playwright handles these via
# --with-deps but we also need build tools for some pip packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (layer-cached unless requirements change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Chromium + all its system libs via playwright's helper.
# vipertls uses playwright under the hood; VIPERTLS_HOME tells it where to look.
ENV VIPERTLS_HOME=/app/vipertls
RUN python -m playwright install-deps chromium && \
    vipertls install-browsers

# Copy the rest of the project
COPY . .

# Railway / Render inject PORT at runtime; fall back to 8080 for local Docker.
ENV PORT=8080

# Use exec form with sh -c so $PORT is expanded at container start time,
# not at image build time. Plain CMD word-form can fail when the runtime
# (Railway/Render) overrides the entrypoint before shell expansion runs.
CMD ["sh", "-c", "uvicorn api:app --host 0.0.0.0 --port ${PORT:-8080}"]
