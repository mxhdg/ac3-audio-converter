#!/bin/bash

INPUT="$1"
LOG_FILE="/logs/ac3convert.log"

log() {
    TS=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TS] $1" | tee -a "$LOG_FILE"
}

# Validate input
if [ -z "$INPUT" ]; then
    log "No input file provided. Exiting."
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    log "Input file not found: $INPUT"
    exit 1
fi

DIR=$(dirname "$INPUT")
BASE=$(basename "$INPUT")
EXT="${BASE##*.}"
NAME="${BASE%.*}"
TEMP="${DIR}/${NAME}-ac3.${EXT}"

log "Processing file: $INPUT"

# Detect primary audio codec
CODEC=$(ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT" | tr '[:upper:]' '[:lower:]')

log "Detected primary audio codec: $CODEC"

# Skip if already compatible
case "$CODEC" in
  ac3|eac3|truehd)
    log "Codec is $CODEC (AC-3/EAC-3/TrueHD). Skipping conversion."
    exit 0
    ;;
esac

# Convert only problematic codecs
case "$CODEC" in
  dts|dts-hd|dca|aac)
    log "Codec $CODEC marked for conversion to AC-3."
    ;;
  *)
    log "Codec $CODEC is not explicitly handled. Leaving as-is."
    exit 0
    ;;
esac

# Perform conversion
log "Starting ffmpeg conversion to AC-3..."
ffmpeg -y -i "$INPUT" \
  -map 0 \
  -c:v copy \
  -c:a ac3 -b:a 640k \
  -c:s copy \
  "$TEMP" >> "$LOG_FILE" 2>&1

# Replace original file
if [ -f "$TEMP" ]; then
    mv -f "$TEMP" "$INPUT"
    log "Conversion complete and original file replaced: $INPUT"
    exit 0
else
    log "Conversion failed. Temporary file not found: $TEMP"
    exit 1
fi
