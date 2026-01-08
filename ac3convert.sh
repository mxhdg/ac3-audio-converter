#!/bin/bash

# Parent directory passed via environment variable
ROOT="${TARGET_PATH}"

if [ -z "$ROOT" ]; then
    echo "ERROR: TARGET_PATH environment variable is not set."
    echo "Usage: docker run -e TARGET_PATH=/path -v /path:/path image"
    exit 1
fi

if [ ! -d "$ROOT" ]; then
    echo "ERROR: Directory not found: $ROOT"
    exit 1
fi

# Logging directory (host-mounted recommended)
LOG_DIR="/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/batch_$TIMESTAMP.log"

echo "Starting batch AC3 conversion in: $ROOT" | tee -a "$LOG_FILE"

# File extensions to process
EXTS="mkv mp4 mov avi"

# Determine number of CPU cores for ffmpeg threading
THREADS=$(nproc)

echo "Using $THREADS threads per file" | tee -a "$LOG_FILE"

# Loop through all media files recursively
for ext in $EXTS; do
    find "$ROOT" -type f -name "*.$ext" | while read -r INPUT; do

        echo "Processing: $INPUT" | tee -a "$LOG_FILE"

        DIR=$(dirname "$INPUT")
        FILE=$(basename "$INPUT")
        BASE="${FILE%.*}"
        TEMP_OUTPUT="$DIR/${BASE}_ac3.${FILE##*.}"

        # Multi-threaded ffmpeg conversion
        ffmpeg -threads "$THREADS" \
            -i "$INPUT" \
            -map 0 \
            -c:v copy \
            -c:a ac3 -b:a 640k \
            -c:s copy \
            "$TEMP_OUTPUT" -y &>> "$LOG_FILE"

        if [ $? -ne 0 ]; then
            echo "FFmpeg failed for: $INPUT" | tee -a "$LOG_FILE"
            rm -f "$TEMP_OUTPUT"
            continue
        fi

        # Atomic replacement
        mv -f "$TEMP_OUTPUT" "$INPUT"
        echo "Converted: $INPUT" | tee -a "$LOG_FILE"
    done
done

echo "Batch conversion complete." | tee -a "$LOG_FILE"
exit 0
