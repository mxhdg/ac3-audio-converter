# AC3 Audio Batch Converter

A standalone, Docker‑based batch converter that recursively scans a directory for media files and converts their audio tracks to AC‑3 while preserving video and subtitle streams. Designed for batch runs, cron jobs, and fully automated workflows. Includes multi‑threading, ETA tracking, persistent state, and detailed logging.

---

## Features

- **Recursive directory scanning** — processes all subfolders under a parent directory
- **Multi‑threaded ffmpeg** — uses all CPU cores by default or a user‑defined thread count
- **Hash‑based identity tracking** — prevents reprocessing even if files are renamed or moved
- **Atomic file replacement** — safe overwrite only after successful conversion
- **Progress tracking** — logs `[current/total]` for each file
- **ETA calculation** — estimates remaining time based on average processing speed
- **Summary report** — converted, skipped, failed, total time
- **FORCE_REPROCESS flag** — override the hash list and reprocess everything
- **Detailed logging** — logs written to a host‑mounted directory
- **Environment‑variable driven** — no command‑line arguments required
- **Lightweight Alpine container** — minimal footprint, fast startup

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

Mount a log directory to persist logs and the persistent hash list:

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

A persistent identity file is stored at:

```
/logs/processed_files.txt
```

---

## Environment Variables

| Variable          | Description                                                   | Default |
|-------------------|---------------------------------------------------------------|---------|
| `TARGET_PATH`     | Parent directory to recursively scan                          | **Required** |
| `THREADS`         | Override ffmpeg thread count                                  | Auto‑detect CPU cores |
| `FORCE_REPROCESS` | Reprocess all files even if hashes match previous runs        | `false` |

---

## Supported File Types

The converter processes the following extensions:

- `.mkv`
- `.mp4`
- `.mov`
- `.avi`

You can modify this list in `ac3convert.sh`.

---

## How It Works

1. The container starts and reads `TARGET_PATH`.
2. It recursively finds all supported media files.
3. For each file:
   - Computes an MD5 hash to determine if it was processed in a previous run
   - Skips the file if the hash matches (unless `FORCE_REPROCESS=true`)
   - Converts audio to AC‑3 at 640k while copying video and subtitles
   - Writes a temporary file and atomically replaces the original
   - Computes a new hash and stores it in `processed_files.txt`
4. After each file, the script logs:
   - Progress (`[current/total]`)
   - ETA based on average processing time
5. At the end, a summary report is written to the log.

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

## GitHub Actions (Tag‑Only Releases)

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
