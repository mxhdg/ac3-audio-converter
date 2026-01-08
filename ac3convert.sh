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

# THREADS override (default: all cores)
if [ -z "$THREADS" ]; then
    THREADS=$(nproc)
fi

echo "Using $THREADS threads per file" | tee -a "$LOG_FILE"

# FORCE_REPROCESS flag
FORCE_REPROCESS="${FORCE_REPROCESS:-false}"
echo "Force reprocess: $FORCE_REPROCESS" | tee -a "$LOG_FILE"

# Persistent processed-file hash list
PROCESSED_FILE_LIST="$LOG_DIR/processed_files.txt"
touch "$PROCESSED_FILE_LIST"

# Count total files matching extensions
TOTAL_FILES=$(find "$ROOT" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" \) | wc -l)
CURRENT=0
CONVERTED=0
SKIPPED=0
FAILED=0

echo "Found $TOTAL_FILES media files to consider" | tee -a "$LOG_FILE"

# Track batch start time for ETA calculations
START_TIME=$(date +%s)

# Helper: format seconds into H:M:S
format_time() {
    local SECONDS=$1
    printf "%02d:%02d:%02d" $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
}

# Process files
find "$ROOT" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" \) | while read -r INPUT; do
    CURRENT=$((CURRENT + 1))

    # Compute hash of current file content
    FILE_HASH=$(md5sum "$INPUT" | awk '{print $1}')

    # Skip if already processed (unless FORCE_REPROCESS=true)
    if [ "$FORCE_REPROCESS" != "true" ] && grep -Fxq "$FILE_HASH" "$PROCESSED_FILE_LIST"; then
        echo "[$CURRENT/$TOTAL_FILES] Skipping already processed file (hash match): $INPUT" | tee -a "$LOG_FILE"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo "[$CURRENT/$TOTAL_FILES] Processing: $INPUT" | tee -a "$LOG_FILE"

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
        echo "[$CURRENT/$TOTAL_FILES] FFmpeg failed for: $INPUT" | tee -a "$LOG_FILE"
        rm -f "$TEMP_OUTPUT"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Atomic replacement
    mv -f "$TEMP_OUTPUT" "$INPUT"

    # Compute new hash after conversion and record it
    NEW_HASH=$(md5sum "$INPUT" | awk '{print $1}')
    echo "$NEW_HASH" >> "$PROCESSED_FILE_LIST"

    CONVERTED=$((CONVERTED + 1))

    # ETA calculation
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))
    AVG_TIME=$((ELAPSED / CURRENT))
    REMAINING_FILES=$((TOTAL_FILES - CURRENT))
    ETA_SECONDS=$((AVG_TIME * REMAINING_FILES))
    ETA_FORMATTED=$(format_time "$ETA_SECONDS")

    echo "[$CURRENT/$TOTAL_FILES] Completed: $INPUT — ETA: $ETA_FORMATTED" | tee -a "$LOG_FILE"

done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
TOTAL_ELAPSED_FORMATTED=$(format_time "$TOTAL_ELAPSED")

# Summary
echo "" | tee -a "$LOG_FILE"
echo "==================== SUMMARY ====================" | tee -a "$LOG_FILE"
echo "Total files scanned:     $TOTAL_FILES" | tee -a "$LOG_FILE"
echo "Converted:               $CONVERTED" | tee -a "$LOG_FILE"
echo "Skipped (already done):  $SKIPPED" | tee -a "$LOG_FILE"
echo "Failed:                  $FAILED" | tee -a "$LOG_FILE"
echo "Total time elapsed:      $TOTAL_ELAPSED_FORMATTED" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

echo "Batch conversion complete." | tee -a "$LOG_FILE"
exit 0
