# Use the hotio sonarr image as the base
FROM ghcr.io/hotio/sonarr:latest

# Install mkvtoolnix
RUN apk add mkvtoolnix

# Copy the script into the container
COPY subtitle_extractor.sh /bin/subtitle_extractor.sh

# Make the script executable
RUN chmod +x /bin/subtitle_extractor.sh

# Preserve the original entrypoint
ENTRYPOINT ["/init"]