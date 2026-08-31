# Releasing

Two ways to publish `sh.mlab/mcp` to the official MCP Registry: the tag driven GitHub Actions workflow (normal path) and a manual run from a laptop (fallback, or first time setup).

Authentication is DNS based: an Ed25519 key pair whose public key sits in a TXT record on the apex of `mlab.sh`. The private key lives only in the GitHub Actions secret `MCP_PRIVATE_KEY`. Never commit it.

## 1. Generate the Ed25519 key pair

```bash
openssl genpkey -algorithm ed25519 -out key.pem
```

Public key, base64, raw 32 bytes, this is what goes in DNS:

```bash
openssl pkey -in key.pem -pubout -outform DER | tail -c 32 | base64
```

Private key, hex, raw 32 bytes, this is what `mcp-publisher login dns` expects:

```bash
openssl pkey -in key.pem -outform DER | tail -c 32 | xxd -p -c 64
```

`key.pem` and `*.pem` are gitignored. Store the hex private key in the repo secret `MCP_PRIVATE_KEY` (Settings > Secrets and variables > Actions) and keep an offline backup of `key.pem`.

## 2. Publish the DNS record

Add a TXT record on the APEX of the domain, not on a selector subdomain:

```
Name:  mlab.sh          (apex, "@" in most DNS panels)
Type:  TXT
Value: v=MCPv1; k=ed25519; p=<base64 pubkey>
```

Check propagation:

```bash
dig +short TXT mlab.sh
```

On key rotation, publish the new record, verify it resolves, then delete the stale `v=MCPv1` TXT record. Leaving an old public key in DNS keeps a retired key valid for publishing.

## 3. Install mcp-publisher

```bash
curl -fsSL "https://github.com/modelcontextprotocol/registry/releases/latest/download/mcp-publisher_darwin_arm64.tar.gz" -o mcp-publisher.tar.gz && tar xzf mcp-publisher.tar.gz mcp-publisher && chmod +x mcp-publisher
```

Swap `darwin_arm64` for `darwin_amd64` or `linux_amd64` as needed. The binary is gitignored.

## 4. Validate, login, publish

```bash
./mcp-publisher validate
```

```bash
./mcp-publisher login dns --domain mlab.sh --private-key "$(openssl pkey -in key.pem -outform DER | tail -c 32 | xxd -p -c 64)"
```

```bash
./mcp-publisher publish
```

## 5. Verify

```bash
curl -sS "https://registry.modelcontextprotocol.io/v0.1/servers?search=sh.mlab" | jq '.servers[] | {name, version}'
```

The version you just published must appear. Also confirm the endpoint is up and requires auth:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -X POST https://mlab.sh/mcp
```

Expected: `401`.

## Bumping a version via tag

`version` in `server.json` is the version of the registry listing, not of the server itself. Bump it on every publish.

1. Add the entry to `CHANGELOG.md`.
2. Commit on `main`.
3. Tag and push:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

The `publish-mcp` workflow rewrites `.version` in `server.json` from the tag with `jq`, validates, logs in with DNS, publishes, then polls the registry until the new version shows up. It runs in the protected `mcp-registry-publish` environment, so it waits for the configured approval before touching the registry.

The committed `server.json` keeps whatever version is on `main`; the tag is the source of truth for what gets published. Keep them in sync by bumping `server.json` in the same commit you tag.
