# LocalTerra Classic

A ready-to-use Terra Classic blockchain for local development and testing.

## Why This Exists

The official `classic-terra/localterra` repository doesn't publish pre-built Docker images, making local development difficult. This project provides:

- **Pre-built Docker images** on Docker Hub
- **Fast block times** (200ms instead of 5s)
- **Pre-funded test accounts** with LUNC, USTC, and other tokens
- **All APIs enabled** (RPC, LCD, gRPC)
- **CosmWasm 1.5.x support** for smart contract development

## Quick Start

### Using GitHub Container Registry (Recommended)

```bash
# Use the current mainnet version (recommended)
docker run -p 26657:26657 -p 1317:1317 -p 9090:9090 ghcr.io/plasticdigits/localterra-cl8y:latest

# Or pin to a specific Terra Classic core version
docker run -p 26657:26657 -p 1317:1317 -p 9090:9090 ghcr.io/plasticdigits/localterra-cl8y:v3.6.2
```

### Using Docker Compose

```yaml
services:
  localterra:
    image: ghcr.io/plasticdigits/localterra-cl8y:latest
    ports:
      - "26657:26657"
      - "1317:1317"
      - "9090:9090"
```

```bash
docker compose up -d
```

### Verify It's Running

```bash
# Check block height
curl http://localhost:26657/status | jq '.result.sync_info.latest_block_height'

# Check test account balance
curl http://localhost:1317/cosmos/bank/v1beta1/balances/terra1x46rqay4d3cssq8gxxvqz8xt6nwlz4td20k38v | jq
```

## Test Accounts

| Account | Address | Use |
|---------|---------|-----|
| test1 | `terra1x46rqay4d3cssq8gxxvqz8xt6nwlz4td20k38v` | Default deployer/operator |

**Mnemonic (DO NOT USE IN PRODUCTION):**
```
notice oak worry limit wrap speak medal online prefer cluster roof addict wrist behave treat actual wasp year salad speed social layer crew genius
```

**Pre-funded Balances:**
- 1,000,000 LUNC (1000000000000 uluna)
- 10,000,000 USTC (10000000000000 uusd)
- 10,000,000 KRT (10000000000000 ukrw)
- 10,000,000 SDT (10000000000000 usdr)
- 10,000,000 EUT (10000000000000 ueur)
- + other stablecoins

## Endpoints

| Service | URL | Description |
|---------|-----|-------------|
| RPC | http://localhost:26657 | Tendermint RPC |
| LCD/REST | http://localhost:1317 | Cosmos REST API |
| gRPC | localhost:9090 | gRPC interface |

## Deploying Contracts

### Store a Contract

```bash
# Copy WASM to container
docker cp my_contract.wasm localterra:/tmp/

# Store contract
docker exec localterra terrad tx wasm store /tmp/my_contract.wasm \
    --from test1 \
    --chain-id localterra \
    --gas auto --gas-adjustment 1.5 \
    --fees 200000000uluna \
    --keyring-backend test \
    -y
```

### Instantiate a Contract

```bash
docker exec localterra terrad tx wasm instantiate 1 '{"key":"value"}' \
    --from test1 \
    --label "my-contract" \
    --admin terra1x46rqay4d3cssq8gxxvqz8xt6nwlz4td20k38v \
    --chain-id localterra \
    --gas auto --gas-adjustment 1.5 \
    --fees 50000000uluna \
    --keyring-backend test \
    -y
```

### Query a Contract

```bash
# Get contract address
docker exec localterra terrad query wasm list-contract-by-code 1 -o json | jq

# Query contract state
curl "http://localhost:1317/cosmwasm/wasm/v1/contract/CONTRACT_ADDR/smart/$(echo -n '{"config":{}}' | base64)"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHAIN_ID` | `localterra` | Chain identifier |
| `MONIKER` | `localterra` | Node moniker |

### Persistence

To persist chain data across restarts:

```yaml
volumes:
  - ./data:/home/terra/.terra
```

### Reset Chain

```bash
docker exec localterra /usr/local/bin/entrypoint.sh init
docker restart localterra
```

## Building Locally

```bash
git clone https://github.com/PlasticDigits/localterra-cl8y.git
cd localterra-cl8y
docker build -t localterra-cl8y .
docker run -p 26657:26657 -p 1317:1317 localterra-cl8y
```

## Differences from Official LocalTerra

| Feature | Official | This Image |
|---------|----------|------------|
| Pre-built images | ❌ None | ✅ Docker Hub |
| Block time | 5s | 200ms |
| Auto-initialization | ❌ Manual | ✅ Automatic |
| API enabled by default | ❌ No | ✅ Yes |
| Documentation | Minimal | Comprehensive |

## Image Versioning

Images are tagged to match [Terra Classic core releases](https://github.com/classic-terra/core/tags):

| Tag | Description |
|-----|-------------|
| `latest` | Current mainnet version (auto-detected from live RPC) |
| `v3.6.2` | Pinned to Terra Classic core v3.6.2 |
| `v3.6.1`, `v3.6.0`, ... | All stable releases available |

The `latest` tag always points to the version running on Terra Classic mainnet (columbus-5), never to release candidates. This is auto-detected by querying public RPC endpoints.

### Building a Specific Version

```bash
# Build with a specific Terra Classic core version
docker build --build-arg TERRA_VERSION=v3.6.2 -t localterra-cl8y:v3.6.2 .
```

## CosmWasm Version

This image uses **wasmvm v3** which supports **CosmWasm 1.5.x** contracts. This is the same version running on Terra Classic mainnet.

## License

Apache-2.0

## Credits

Based on [classic-terra/core](https://github.com/classic-terra/core).
