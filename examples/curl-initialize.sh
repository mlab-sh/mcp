#!/usr/bin/env bash
# Minimal MCP initialize handshake against https://mlab.sh/mcp
# Usage: MLAB_TOKEN=mcp_xxx ./curl-initialize.sh
set -euo pipefail

curl -sS -X POST https://mlab.sh/mcp \
  -H "Authorization: Bearer ${MLAB_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-06-18",
      "capabilities": {},
      "clientInfo": { "name": "curl", "version": "1.0.0" }
    }
  }'
