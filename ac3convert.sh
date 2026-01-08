#!/bin/bash

# Determine whether this was called by Sonarr or Radarr
# Sonarr provides: $sonarr_episodefile_path
# Radarr provides: $radarr_moviefile_path

if [ -n "$sonarr_episodefile_path" ]; then
    INPUT="$sonarr_episodefile_path"
    SOURCE="Sonarr"
elif [ -n "$radarr_moviefile_path" ]; then
    INPUT="$radarr_moviefile_path"
    SOURCE="Radarr"
else
    echo "No valid Sonarr or Radarr environment variable found."
    exit 1
fi

# Logging directory
LOG_DIR="/config/logs/ac3-audio-converter"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/convert_$TIMESTAMP.log"

echo "[$SOURCE] Starting AC3 conversion for: $INPUT" | tee -a "$LOG_FILE"

# Extract directory and filename
DIR=$(dirname "$INPUT")
FILE=$(basename "$INPUT")
EXT="${FILE##*.}"
BASE="${FILE%.*}"

TEMP_OUTPUT="$DIR/${BASE}_ac3.$EXT"

# Run ffmpeg conversion
ffmpeg -i "$INPUT" -map 0 -c:v copy -c:a ac3 -b:a 640k -c:s copy "$TEMP_OUTPUT" -y &>> "$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "FFmpeg conversion failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Atomic replacement
mv -f "$TEMP_OUTPUT" "$INPUT"

echo "[$SOURCE] Conversion complete and file replaced successfully" | tee -a "$LOG_FILE"
exit 0
