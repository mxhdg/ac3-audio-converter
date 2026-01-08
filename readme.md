# AC3 Audio Batch Converter

A simple, standalone Docker-based batch converter that recursively scans a directory for media files and converts their audio tracks to AC-3 while preserving video and subtitle streams. Designed for manual runs, cron jobs, or external automation — no Sonarr/Radarr integration required.

---

## Features

- Recursively scans all subfolders under a parent directory
- Converts audio to AC-3 (`640k`) while copying video and subtitles
- Atomic file replacement (safe overwrite)
- Logs all operations to a host-mounted directory
- Runs once and exits — perfect for batch jobs
- Lightweight Alpine-based container
- Triggered via environment variable (`TARGET_PATH`)

---

## Usage

### Basic Run

Mount your media directory and pass it as `TARGET_PATH`:

```bash
docker run --rm \
  -e TARGET_PATH="/data" \
  -v /data:/data \
  ghcr.io/mxhdg/ac3-audio-converter:latest
```

### With Logging

Mount a log directory to persist logs:

```bash
docker run --rm \
  -e TARGET_PATH="/data" \
  -v /data:/data \
  -v /DATA/AppData/ac3/logs:/logs \
  ghcr.io/mxhdg/ac3-audio-converter:latest
```

Logs will be written to:

```
/logs/batch_YYYY-MM-DD_HH-MM-SS.log
```

---

## Supported File Types

The converter processes the following extensions:

- `.mkv`
- `.mp4`
- `.mov`
- `.avi`

You can modify this list in `ac3convert.sh`.

---

## Environment Variables

| Variable      | Description                                      | Required |
|---------------|--------------------------------------------------|----------|
| `TARGET_PATH` | The parent directory to recursively scan         | Yes      |

---

## How It Works

1. The container starts and reads `TARGET_PATH`.
2. It recursively finds all media files under that directory.
3. For each file:
   - Video and subtitles are copied as-is
   - Audio is converted to AC-3 at 640k
   - A temporary file is created
   - The original file is atomically replaced
4. A detailed log is written to `/logs`.

---

## Example Cron Job

Run the converter nightly:

```bash
0 3 * * * docker run --rm \
  -e TARGET_PATH="/data" \
  -v /data:/data \
  -v /DATA/AppData/ac3/logs:/logs \
  ghcr.io/mxhdg/ac3-audio-converter:latest
```

---

## Development

### Build Locally

```bash
docker build -t ac3-audio-converter .
```

### Run Locally

```bash
docker run --rm \
  -e TARGET_PATH="/data" \
  -v /data:/data \
  ac3-audio-converter
```

---

## GitHub Actions (Tag-Only Releases)

This project only publishes Docker images when a **semantic version tag** is pushed:

```bash
git tag v1.0.0
git push --tags
```

The workflow will:

- Build the container
- Tag it with semantic versions
- Push it to GHCR

No builds occur on normal commits.

---

## License

MIT License. Use freely and modify as needed.
