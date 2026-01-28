FROM alpine:latest

RUN apk add --no-cache postgresql-client rclone tzdata zip

COPY scripts/ /scripts/
RUN chmod +x /scripts/entrypoint.sh

ENTRYPOINT ["/bin/sh", "/scripts/entrypoint.sh"]