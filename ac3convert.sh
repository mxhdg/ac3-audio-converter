#!/bin/bash

INPUT="$1"
LOG_DIR="/config/logs/ac3-audio-converter"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/convert_$TIMESTAMP.log"

mkdir -p "$LOG_DIR"

echo "Starting AC3 conversion for: $INPUT" | tee -a "$LOG_FILE"

# Extract directory and filename
DIR=$(dirname "$INPUT")
FILE=$(basename "$INPUT")
EXT="${FILE##*.}"
BASE="${FILE%.*}"

TEMP_OUTPUT="$DIR/${BASE}_ac3.$EXT"

# Convert audio to AC3
ffmpeg -i "$INPUT" -map 0 -c:v copy -c:a ac3 -b:a 640k -c:s copy "$TEMP_OUTPUT" -y &>> "$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "FFmpeg conversion failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Atomic replacement
mv -f "$TEMP_OUTPUT" "$INPUT"

echo "Conversion complete and file replaced successfully" | tee -a "$LOG_FILE"
exit 0
