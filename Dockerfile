# TODO(bwplotka): Move to 1.23 once ARM QEMU building is fixed https://github.com/golang/go/issues/68976
FROM golang:1.22.7@sha256:4594271250150c1a322ed749abfd218e1a8c6eb1ade90872e325a664412e2037 AS gobase
WORKDIR /app
COPY . ./
RUN mkdir /etc/alertmanager
RUN mkdir /alertmanager
RUN CGO_ENABLED=1 GOEXPERIMENT=boringcrypto \
    go build \
    -tags boring \
    -mod=vendor \
    -ldflags="-X github.com/prometheus/common/version.Version=$(cat VERSION) \
    -X github.com/prometheus/common/version.BuildDate=$(date --iso-8601=seconds)" \
    ./cmd/alertmanager

FROM gke.gcr.io/gke-distroless/libc:gke_distroless_20240907.00_p0@sha256:2cdd63fbfb7bc7482f28328494c8cd6783eba0d4c1007c164a9deee3656b618b
COPY --from=gobase /app/alertmanager /bin/alertmanager
COPY --from=gobase --chown=nobody:nobody /etc/alertmanager /etc/alertmanager
COPY --from=gobase --chown=nobody:nobody /alertmanager /alertmanager
COPY LICENSE LICENSE
COPY NOTICE NOTICE

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]
