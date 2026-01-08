#!/bin/bash

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

LOG_DIR="/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/batch_$TIMESTAMP.log"

echo "Starting batch AC3 conversion in: $ROOT" | tee -a "$LOG_FILE"

EXTS="mkv mp4 mov avi"
THREADS=$(nproc)

echo "Using $THREADS threads per file" | tee -a "$LOG_FILE"

# Count total files
TOTAL_FILES=$(find "$ROOT" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" \) | wc -l)
CURRENT=0

echo "Found $TOTAL_FILES media files to process" | tee -a "$LOG_FILE"

# Track start time
START_TIME=$(date +%s)

# Helper: format seconds into H:M:S
format_time() {
    local SECONDS=$1
    printf "%02d:%02d:%02d" $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
}

# Process files
find "$ROOT" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" \) | while read -r INPUT; do

    CURRENT=$((CURRENT + 1))

    echo "[$CURRENT/$TOTAL_FILES] Processing: $INPUT" | tee -a "$LOG_FILE"

    DIR=$(dirname "$INPUT")
    FILE=$(basename "$INPUT")
    BASE="${FILE%.*}"
    TEMP_OUTPUT="$DIR/${BASE}_ac3.${FILE##*.}"

    ffmpeg -threads "$THREADS" \
        -i "$INPUT" \
        -map 0 \
        -c:v copy \
        -c:a ac3 -b:a 640k \
        -c:s copy \
        "$TEMP_OUTPUT" -y &>> "$LOG_FILE"

    if [ $? -ne 0 ]; then
        echo "[$CURRENT/$TOTAL_FILES] FFmpeg failed for: $INPUT" | tee -a "$LOG_FILE"
        rm -f "$TEMP_OUTPUT"
        continue
    fi

    mv -f "$TEMP_OUTPUT" "$INPUT"

    # Calculate ETA
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))
    AVG_TIME=$((ELAPSED / CURRENT))
    REMAINING_FILES=$((TOTAL_FILES - CURRENT))
    ETA_SECONDS=$((AVG_TIME * REMAINING_FILES))
    ETA_FORMATTED=$(format_time $ETA_SECONDS)

    echo "[$CURRENT/$TOTAL_FILES] Completed: $INPUT — ETA: $ETA_FORMATTED" | tee -a "$LOG_FILE"

done

echo "Batch conversion complete. Processed $TOTAL_FILES files." | tee -a "$LOG_FILE"
exit 0
