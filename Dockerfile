FROM debian:stable-slim

# Install ffmpeg + dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        ca-certificates \
        bash \
        coreutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g 1000 converter && \
    useradd -u 1000 -g converter -m converter

# Create log directory
RUN mkdir -p /logs && chown converter:converter /logs

# Copy conversion script
COPY ac3convert.sh /usr/local/bin/ac3convert.sh
RUN chmod +x /usr/local/bin/ac3convert.sh && \
    chown converter:converter /usr/local/bin/ac3convert.sh

# Expose volumes
VOLUME ["/media", "/logs"]

# Switch to non-root user
USER converter

# Run the converter script by default
ENTRYPOINT ["/usr/local/bin/ac3convert.sh"]
