FROM alpine:latest

RUN apk add --no-cache postgresql-client rclone tzdata zip curl bash

COPY scripts/ /scripts/
RUN chmod +x /scripts/entrypoint.sh

ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]