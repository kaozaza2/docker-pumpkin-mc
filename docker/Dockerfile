# syntax=docker/dockerfile:1
ARG PUMPKIN_SOURCE=release

FROM alpine:3.24 AS release
ARG TARGETARCH
ARG PUMPKIN_VERSION=nightly
RUN apk add --no-cache curl && \
    case "${TARGETARCH}" in \
        amd64) ARCH=X64 ;; \
        arm64) ARCH=ARM64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/Pumpkin-MC/Pumpkin/releases/download/${PUMPKIN_VERSION}/pumpkin-${ARCH}-Linux-musl" -o /pumpkin && \
    chmod +x /pumpkin

FROM rust:1-alpine3.24 AS source
ENV RUSTFLAGS="-C target-feature=-crt-static"
RUN apk add --no-cache musl-dev git
WORKDIR /src
COPY pumpkin/ .
RUN rustup show active-toolchain || rustup toolchain install
RUN --mount=type=cache,sharing=private,target=/src/target \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry \
    cargo build --release -p pumpkin && cp target/release/pumpkin /pumpkin

FROM ${PUMPKIN_SOURCE} AS binary

FROM alpine:3.24
RUN apk add --no-cache ca-certificates curl jq libgcc su-exec tini tzdata yq-go
COPY --from=binary /pumpkin /usr/local/bin/pumpkin
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

ENV UID=1000 GID=1000 RUST_BACKTRACE=1
WORKDIR /data
VOLUME /data
EXPOSE 25565/tcp 19132/udp

HEALTHCHECK --start-period=1m --interval=30s --timeout=3s --retries=3 \
    CMD nc -z 127.0.0.1 "${SERVER_PORT:-25565}" || exit 1
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
