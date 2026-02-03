# LocalTerra Classic - Pre-configured Terra Classic for local development
#
# This image provides a ready-to-use Terra Classic blockchain with:
# - Fast block times (200ms)
# - Pre-funded test accounts
# - All APIs enabled (RPC, LCD, gRPC)
# - CosmWasm 1.5.x support
#
# Based on: https://github.com/classic-terra/core/blob/main/Dockerfile
#
# Usage:
#   docker run -p 26657:26657 -p 1317:1317 -p 9090:9090 cl8y/localterra
#
# Build:
#   docker build -t cl8y/localterra .

# ============================================================================
# Stage 1: Build terrad from classic-terra/core (mirrors their Dockerfile)
# ============================================================================
FROM golang:1.24-bookworm AS builder

# Terra Classic core version to build
# Default matches current mainnet - override with --build-arg TERRA_VERSION=vX.Y.Z
ARG TERRA_VERSION=v3.6.2

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    make \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Clone classic-terra/core at specified version
WORKDIR /build
RUN git clone --depth 1 --branch ${TERRA_VERSION} https://github.com/classic-terra/core.git .

# Build terrad (using glibc-based libwasmvm)
RUN make install

# Find and copy libwasmvm to a known location for the next stage
# The path varies by wasmvm version (v1.x, v2.x, v3.x have different module paths)
# Must use x86_64 version for linux/amd64 platform
RUN WASMVM_SO=$(find /go/pkg/mod -name "libwasmvm.x86_64.so" -type f | head -1) && \
    cp "$WASMVM_SO" /usr/lib/ && \
    cd /usr/lib && \
    ln -sf libwasmvm.x86_64.so libwasmvm.so

# ============================================================================
# Stage 2: Runtime image with pre-configured chain
# ============================================================================
FROM debian:bookworm-slim

# Re-declare ARG to use in this stage (ARGs don't persist across FROM)
ARG TERRA_VERSION=v3.6.2

# Labels for image metadata
LABEL org.opencontainers.image.source="https://github.com/PlasticDigits/localterra-cl8y"
LABEL org.opencontainers.image.description="LocalTerra Classic - Pre-configured Terra Classic for local development"
LABEL org.opencontainers.image.terra-core-version="${TERRA_VERSION}"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy terrad binary
COPY --from=builder /go/bin/terrad /usr/local/bin/terrad

# Copy libwasmvm (copied to /usr/lib in builder stage for portability across wasmvm versions)
COPY --from=builder /usr/lib/libwasmvm* /usr/lib/

# Create terra user and home directory
RUN useradd -m -u 1000 terra && \
    mkdir -p /home/terra/.terra && \
    chown -R terra:terra /home/terra

# Copy initialization and entrypoint scripts
COPY scripts/init-chain.sh /usr/local/bin/init-chain.sh
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/*.sh

# Set working directory
WORKDIR /home/terra

# Environment variables
ENV TERRA_HOME=/home/terra/.terra
ENV CHAIN_ID=localterra
ENV MONIKER=localterra

# Expose ports
# 26657 - Tendermint RPC
# 1317  - REST/LCD API
# 9090  - gRPC
# 9091  - gRPC-web
EXPOSE 26657 1317 9090 9091

# Volume for chain data (optional - for persistence)
VOLUME ["/home/terra/.terra"]

# Run as terra user
USER terra

# Entrypoint handles initialization and startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["start"]
