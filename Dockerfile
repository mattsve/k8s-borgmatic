FROM monachus/borgmatic:v1.5.10
RUN apk add --no-cache jq tzdata

COPY scripts/ /scripts
COPY config.yaml /etc/borgmatic/config.yaml

ENTRYPOINT ["/scripts/entrypoint.sh"]