ARG PYTHON_VERSION=3.6-alpine3.7

FROM python:${PYTHON_VERSION} as builder
ARG BORGMATIC_VERSION=1.5.10
ENV PYTHONUNBUFFERED 1

WORKDIR /wheels
RUN pip3 wheel borgmatic==${BORGMATIC_VERSION}

FROM python:${PYTHON_VERSION}
ARG BORGMATIC_VERSION=1.5.10

COPY --from=builder /wheels /wheels

RUN apk --no-cache add borgbackup openssh-client bash jq tzdata \
    && pip3 install -f /wheels borgmatic==${BORGMATIC_VERSION} \
    && rm -fr /var/cache/apk/* /wheels /.cache

COPY scripts/ /scripts
COPY config.yaml /etc/borgmatic/config.yaml

ENTRYPOINT ["/scripts/entrypoint.sh"]
