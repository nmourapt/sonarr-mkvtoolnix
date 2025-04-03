# Use the hotio sonarr image as the base
FROM ghcr.io/hotio/sonarr:latest

# Install mkvtoolnix
RUN apk add mkvtoolnix

# Preserve the original entrypoint
ENTRYPOINT ["/init"]