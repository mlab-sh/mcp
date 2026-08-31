# mlab.sh MCP server

Public metadata and connection guide for the remote MCP server at `https://mlab.sh/mcp`, a threat intelligence server for SOC and DFIR work.

This repo is the registry listing and the documentation. It is not the server source: the server runs inside the mlab.sh backend and is closed source.

## Connect

Endpoint: `https://mlab.sh/mcp` (Streamable HTTP via POST, SSE via GET).

### Claude.ai

Settings > Connectors > Add custom connector, then paste the URL. OAuth runs in the browser, no token to copy.

```
https://mlab.sh/mcp
```

### Claude Desktop

`claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "mlab": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://mlab.sh/mcp",
        "--header",
        "Authorization: Bearer mcp_xxx"
      ]
    }
  }
}
```

Drop the `--header` pair to use OAuth instead of a static token.

### Cursor

`~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "mlab": {
      "url": "https://mlab.sh/mcp",
      "headers": {
        "Authorization": "Bearer mcp_xxx"
      }
    }
  }
}
```

### VS Code

`.vscode/mcp.json`:

```json
{
  "servers": {
    "mlab": {
      "type": "http",
      "url": "https://mlab.sh/mcp",
      "headers": {
        "Authorization": "Bearer mcp_xxx"
      }
    }
  }
}
```

### curl

```bash
curl -sS -X POST https://mlab.sh/mcp \
  -H "Authorization: Bearer mcp_xxx" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl","version":"1.0.0"}}}'
```

Ready to paste versions of these four configs live in [`examples/`](examples).

Officially supported clients are Claude.ai and Claude Desktop. Other MCP clients (Cursor, VS Code, Windsurf and friends) work but are best effort.

## Tools

### IOC enrichment

| Tool | Purpose |
| --- | --- |
| `detect_ioc` | Auto detect the IOC type of a value and return relevant threat intel |
| `scan_ip` | Threat intel for an IPv4 or IPv6 address |
| `scan_url` | Static analysis of a URL without visiting it |
| `scan_hash` | File hash lookup (MD5, SHA1, SHA256) in CIRCL hashlookup |
| `scan_crypto` | Threat intel for a blockchain address: labels, sanctions, risk score, 18 chains |
| `scan_email` | Offline style analysis of an email address |
| `scan_phone` | Offline style analysis of a phone number |
| `scan_mac` | Offline style analysis of a MAC address |
| `smishing_risk` | Score an SMS for smishing |

### Vulnerabilities and actors

| Tool | Purpose |
| --- | --- |
| `cve_search` | Search CVEs |
| `cve_detail` | Full CVE record |
| `actors_by_cve` | Threat actors known to exploit a CVE |
| `search_actors` | Search threat actors |
| `get_actor` | Full threat actor profile |

### Scanning

| Tool | Purpose |
| --- | --- |
| `start_domain_scan` | Launch a domain scan: DNS, subdomains, SSL, security.txt, robots.txt |
| `get_domain_scan_results` | Poll the results of a domain scan |
| `scan_bash` | Static analysis of an inline shell script |
| `scan_sbom` | Scan a dependency lockfile or SBOM for known CVEs |

### Account

| Tool | Purpose |
| --- | --- |
| `get_scan_history` | Past scans for the account |
| `get_scan_limits` | Current quotas and remaining scans |
| `get_account_info` | Account details |
| `add_bookmark` | Bookmark an IOC |
| `remove_bookmark` | Remove a bookmarked IOC |
| `get_bookmarks` | List bookmarked IOCs |
| `hello_world` | Connectivity check |

## Authentication

OAuth 2.1 is the recommended path: authorization code with PKCE S256, dynamic client registration, CIMD supported. The server advertises its metadata at `https://mlab.sh/.well-known/oauth-authorization-server`, so a compliant client only needs the endpoint URL.

If your client does not speak OAuth, create a static token in Account > Settings > MCP Tokens and send it as `Authorization: Bearer mcp_xxx`.

Full details: https://doc.mlab.sh/docs/mlab.sh/integrations/mcp

## Rate limits and quotas

Limits follow your mlab.sh account plan. Call `get_scan_limits` to read the quotas and remaining budget that apply to your account.

## Registry

Published to the official MCP Registry as `sh.mlab/mcp`.

https://registry.modelcontextprotocol.io/v0.1/servers?search=sh.mlab

## Other public servers

`https://news.mlab.sh/mcp` is a separate, unauthenticated, read only MCP server exposing a cyber news index. It is not published from this repo.

## Security

Report vulnerabilities to security@mlab.sh. See https://mlab.sh/security.txt and [SECURITY.md](SECURITY.md).

## License

MIT, see [LICENSE](LICENSE).
