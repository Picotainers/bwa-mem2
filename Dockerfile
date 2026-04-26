# syntax=docker/dockerfile:1

FROM debian:bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        g++ \
        git \
        libnuma-dev \
        make \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --recurse-submodules https://github.com/bwa-mem2/bwa-mem2.git

WORKDIR /src/bwa-mem2
RUN make -j"$(nproc)" \
    && install -d /out/usr/local/libexec /out/usr/local/bin \
    && for bin in bwa-mem2 bwa-mem2.avx bwa-mem2.avx2 bwa-mem2.avx512bw bwa-mem2.sse41 bwa-mem2.sse42; do \
        if [ -x "$bin" ]; then install -m755 "$bin" "/out/usr/local/libexec/$bin"; fi; \
    done \
    && printf '%s\n' \
        '#!/bin/sh' \
        'set -eu' \
        'if [ "${1:-}" = "bwa-mem2" ]; then shift; fi' \
        'if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then' \
        '  /usr/local/libexec/bwa-mem2 >/dev/stdout 2>/dev/stderr || true' \
        '  exit 0' \
        'fi' \
        'exec /usr/local/libexec/bwa-mem2 "$@"' \
      > /out/usr/local/bin/bwa-mem2 \
    && chmod +x /out/usr/local/bin/bwa-mem2

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libgomp1 \
        libnuma1 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/ /
WORKDIR /data

ENTRYPOINT ["/usr/local/bin/bwa-mem2"]
CMD ["--help"]
