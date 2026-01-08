FROM alpine:3.19

# Install ffmpeg
RUN apk add --no-cache ffmpeg bash

# Create mod directory structure
RUN mkdir -p /mod/usr/local/bin

# Copy the conversion script into the mod path
COPY ac3convert.sh /mod/usr/local/bin/ac3convert

# Ensure the script is executable
RUN chmod +x /mod/usr/local/bin/ac3convert

# No entrypoint needed — this is a LinuxServer Mod
