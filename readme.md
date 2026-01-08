# AC3 Audio Converter (LinuxServer Mod Compatible)

A lightweight, reliable AC‑3 audio conversion tool designed for automated post‑processing in **Sonarr** and **Radarr**.
This project is packaged as a **LinuxServer Mod**, meaning it integrates directly into the official `linuxserver/sonarr` and `linuxserver/radarr` containers without requiring Docker‑in‑Docker, socket mounts, or external scripts.

The converter runs **inside** the Sonarr/Radarr container and is triggered via the built‑in **Custom Script** connection.

---

## Features

- Converts audio tracks to **AC‑3 (Dolby Digital)** using ffmpeg
- Preserves video and subtitle streams
- Performs **atomic replacement** of the original file
- Logs all conversions to `/config/logs/ac3-audio-converter`
- Works seamlessly with:
  - LinuxServer Sonarr
  - LinuxServer Radarr
  - DOCKER_MODS system
- Versioned and published automatically via GitHub Actions + GHCR

---

## Installation (LinuxServer Mods)

Add the mod to your Sonarr or Radarr container using the `DOCKER_MODS` environment variable.

### Sonarr

```
-e DOCKER_MODS=linuxserver/mods:sonarr-striptracks,ghcr.io/mxhdg/ac3-audio-converter:latest
```

### Radarr

```
-e DOCKER_MODS=linuxserver/mods:radarr-striptracks,ghcr.io/mxhdg/ac3-audio-converter:latest
```

LinuxServer will automatically:

- pull the mod image
- extract `/mod/usr/local/bin/ac3convert`
- place it into `/usr/local/bin/ac3convert` inside the container

No additional configuration is required.

---

## Sonarr Setup (Custom Script)

1. Go to **Settings → Connect**
2. Click **Add → Custom Script**
3. Configure:

**Path:**
```
/usr/local/bin/ac3convert
```

**Arguments:**
```
"$episode_file_path"
```

**Triggers:**
- On Import
- On Upgrade (recommended)

---

## Radarr Setup (Custom Script)

1. Go to **Settings → Connect**
2. Click **Add → Custom Script**
3. Configure:

**Path:**
```
/usr/local/bin/ac3convert
```

**Arguments:**
```
"$movie_file_path"
```

**Triggers:**
- On Import
- On Upgrade (recommended)

---

## Logging

All logs are written to:

```
/config/logs/ac3-audio-converter/
```

Each run generates a timestamped log file for easy debugging.

---

## How It Works

When Sonarr or Radarr imports a file, it calls:

```
/usr/local/bin/ac3convert <full_path_to_media_file>
```

The script:

1. Reads the input file
2. Creates a temporary AC‑3‑encoded version
3. Atomically replaces the original file
4. Logs the entire process

Because the script runs *inside* the Sonarr/Radarr container, it sees the same media paths the application sees — no path translation required.

---

## Versioning & Releases

This project uses **semantic versioning** and publishes images to GHCR.

To cut a release:

```
git tag v1.0.0
git push --tags
```

GitHub Actions automatically builds and publishes:

- `v1.0.0`
- `v1.0`
- `v1`
- `latest`
- `sha-<commit>`

Images are available at:

```
ghcr.io/mxhdg/ac3-audio-converter
```

---

## Development

The mod image places the script here:

```
/mod/usr/local/bin/ac3convert
```

LinuxServer automatically copies this into:

```
/usr/local/bin/ac3convert
```

inside the Sonarr/Radarr container.

To update the script:

1. Modify `ac3convert.sh`
2. Build and push a new version
3. Tag a release
4. Restart Sonarr/Radarr to pull the updated mod

---

## Requirements

- LinuxServer Sonarr or Radarr container
- ffmpeg (installed automatically by the mod)
- DOCKER_MODS enabled

---

## License

MIT License.
Feel free to fork, modify, and integrate into your own automation workflows.
