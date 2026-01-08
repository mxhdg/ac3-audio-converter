FROM alpine:3.19

# Install ffmpeg and bash
RUN apk add --no-cache ffmpeg bash

# Create ONLY the mod directory
RUN mkdir -p /mod/usr/local/bin

# Copy your script into the mod path
COPY ac3convert.sh /mod/usr/local/bin/ac3convert

# Make it executable
RUN chmod +x /mod/usr/local/bin/ac3convert
