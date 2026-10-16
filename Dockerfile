FROM golang:1.26-bookworm AS build
ARG IPATOOL_COMMIT=1b9ff28eb467
WORKDIR /src
COPY engine/ ./engine/
RUN git clone --quiet https://github.com/majd/ipatool.git engine/.ipatool \
 && git -C engine/.ipatool checkout --quiet ${IPATOOL_COMMIT} \
 && rm -rf engine/.ipatool/.git
WORKDIR /src/engine
RUN CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" -o /ipa-server ./cmd/server

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --create-home --home-dir /var/lib/ipa-server ipa
COPY --from=build /ipa-server /usr/local/bin/ipa-server
ENV IPA_SERVER_ADDRESS=:8080 \
    IPA_SERVER_CACHE=/var/lib/ipa-server
USER ipa
WORKDIR /var/lib/ipa-server
EXPOSE 8080
VOLUME ["/var/lib/ipa-server"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s \
  CMD ["/usr/local/bin/ipa-server", "-check"]
ENTRYPOINT ["/usr/local/bin/ipa-server"]
