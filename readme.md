# ac3-audio-converter

`ac3-audio-converter` is a lightweight, event‑driven Docker add‑on designed to fix incompatible audio codecs in media files imported by Radarr and Sonarr. It converts DTS, DTS‑HD, DCA, and AAC audio tracks to AC‑3 while preserving video, subtitles, and Atmos‑friendly formats like TrueHD and EAC‑3.

This container is **not a long‑running service**. It runs only when triggered, performs the conversion, replaces the original file atomically, logs the result, and exits.

---

## Features

- Converts **DTS / DTS‑HD / DCA / AAC → AC‑3 (640k)**
- Preserves **AC‑3, EAC‑3, and TrueHD/Atmos**
- Atomic file replacement (no partial files)
- Non‑root container for safer operation
- Works seamlessly with Radarr and Sonarr via Custom Scripts
- Clean logs written to a host‑mounted directory
- Debian‑based for predictable FFmpeg behavior

---

## How It Works

Radarr/Sonarr triggers the container using a `docker run` command. The container:

1. Mounts your media directory  
2. Detects the primary audio codec  
3. Converts only when needed  
4. Replaces the original file  
5. Writes logs  
6. Exits  

No background processes. No idle containers.
