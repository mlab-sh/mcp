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

48 tools. `tools/list` only shows a token the tools its role and plan can use, so a client never sees a tool that would refuse every call. Every tool carries MCP annotations (read only, destructive, idempotent, open world), so a host can tell what it may run unattended. No tool deletes anything.

Parameters marked `?` are optional.

### Who can use what

| Group | Plan | Role |
| --- | --- | --- |
| IOC lookups, domain scans, `scan_bash`, `scan_sbom` | Any | Owner, admin, member (viewers cannot spend quota) |
| CVEs, actors, account, bookmarks, history | Any | Any, viewer included |
| Cases: reading (`list_cases`, `get_case`) | Team, Enterprise | Any, viewer included |
| Cases: writing (`create_case`, `add_case_indicators`, `add_case_comment`) | Team, Enterprise | Owner, admin, member |
| Workspaces | Team (1 workspace), Enterprise (up to 20) | Any; members only see the workspaces they were added to, owners and admins see all |

Quotas are counted per organization over a rolling 24 hour window. `get_scan_limits` reads what is left.

### IOC lookups

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `detect_ioc` | `value` | Detects the type of an indicator (IPv4, IPv6, CIDR, domain, URL, MD5/SHA1/SHA256/SHA512 hash, email, MAC) and returns the relevant intel. A domain is typed, not scanned: use `start_domain_scan` for that. An IP spends IP quota |
| `scan_ip` | `ip` | For an address: geolocation, ISP, ASN, datacenter / proxy / VPN / mobile network, TOR consensus status, forward confirmed reverse DNS, RDAP record with the abuse contact. For a CIDR range: network, broadcast, host window, netmask, size, reserved blocks. Addresses spend IP quota (cached 7 days); ranges are free |
| `scan_url` | `url`, `resolve?` | Static analysis without visiting: scheme, host with its Unicode and punycode forms, IP literal hosts, credentials in the URL, dangerous extensions, shorteners, embedded redirect targets, and what a past domain scan recorded about the host. `resolve` follows the link to its real destination, the only part that visits anything. No quota |
| `scan_hash` | `hash` | MD5, SHA1 or SHA256 against CIRCL hashlookup (NIST NSRL): known good, known malicious or unknown, each feed's own answer, malware family, product and file name, CIRCL trust score, and `mlab_sample` when mlab analysed the file itself. `unknown` is not the same as safe. No quota |
| `scan_crypto` | `address`, `chain?` | Labels, sanctions, risk score and address type across 18 chains (Bitcoin, Ethereum and 12 other EVM chains, Tron, Solana, TON, Dogecoin), with a checksum check. EVM addresses do not reveal their chain: pass `chain` when you know it. Spends crypto quota |
| `scan_email` | `email` | Mailbox type (disposable, role, consumer, standard), SPF / DKIM / DMARC spoofability of its domain, MX presence, domain age when scanned, and a 0 to 100 score with its weighted reasons. No quota |
| `scan_phone` | `number` | E.164 number: validity, country, line type, allocated operator, formatting and scam shaped findings. Offline, no quota |
| `scan_mac` | `mac` | OUI vendor, unicast or multicast, universal or local administration, randomized or virtual interface, EUI-64 IPv6, other formats. Offline, no quota |

### Domain scans and code

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `start_domain_scan` | `domain` | Returns a recent completed scan right away, or launches a new one and returns `{"status": "started"}`. A new scan contacts the target and spends domain scan quota |
| `get_domain_scan_results` | `domain` | Results of a domain scan: DNS records, subdomains, SSL certificates, security.txt, robots.txt. Call again while the status is `pending` or `scanning` |
| `scan_bash` | `content`, `filename?` | Static analysis of an inline shell script: sha256, every IOC it holds, and well known suspicious constructs (download piped to a shell, base64 decoding, `/dev/tcp` reverse shells, persistence, anti forensics, destructive deletes). Nothing runs or is stored. No quota |
| `scan_sbom` | `content`, `format?` | Known vulnerabilities in a lockfile or SBOM (npm, yarn, pnpm, Cargo, pip, Poetry, uv, PDM, Pipfile, Composer, Gem, Go, Maven, Gradle, NuGet, pub, Hex, mise, CycloneDX, SPDX), one finding per package and CVE, worst first, with the fixed version and what the scan could not cover. Matched server side on vuln.mlab.sh (OSV, NVD for CPE only components). 2 MB at most; `format` defaults to `auto` |

### CVEs and threat actors

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `cve_search` | `query`, `severity?`, `date_start?`, `date_end?`, `limit?`, `page?` | CVEs by keyword, product, vendor or ID, filtered by severity (CRITICAL, HIGH, MEDIUM, LOW) and publication date, with CVSS, EPSS and KEV status |
| `cve_detail` | `cve_id` | The full record: CVSS vector breakdown, affected products, references, CWEs, EPSS, CISA KEV status |
| `search_actors` | `query`, `origin?`, `motivation?`, `sector?`, `limit?` | Threat actors by name or alias from the MISP Galaxy cluster (CC0), narrowed by origin, incident type or targeted sector. Returns the slug for `get_actor` |
| `get_actor` | `slug` | MISP Galaxy profile (origin, suspected sponsor, synonyms, targeted countries and sectors, references) with the MITRE ATT&CK tools and techniques attributed to it. Keep the `sources` block when quoting: it carries MITRE's notice |

### Cases

Team and Enterprise. Each call goes through the same checks as the case pages.

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `list_cases` | none | The organization's cases, open ones first, with indicator and comment counts |
| `get_case` | `uuid` | Title, summary, status, every indicator with a link to its analysis, and the comment thread |
| `create_case` | `title`, `summary?` | Opens a case and returns the uuid the other case tools take |
| `add_case_indicators` | `uuid`, `indicators` | Files a paste of indicators (one per line, or comma or space separated, mixed types), typed automatically; anything mlab cannot look up comes back in `skipped` with the reason |
| `add_case_comment` | `uuid`, `body`, `indicator_uuid?` | A note on the case, or on one of its indicators |

### Workspaces

Team and Enterprise, and only in a workspace whose admin turned on **AI agents (MCP)**: a workspace keeps its data on the organization's own hosts, and an answer goes to the LLM provider of whoever asked. `workspace_list` says which workspaces are open. Every tool except `workspace_list` takes `workspace` (the uuid from `workspace_list`). Each call is written to the workspace's audit log.

The tools read, and can start an index or a YARA scan. Creating, deleting, enrolling, members, policies, pushing a cluster config and binary downloads stay in the app. Answers carry data sent by the hosts, which may contain text planted by an attacker: the server says so before every answer.

**Agents and memory forensics (engram)**

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `workspace_list` | none | The workspaces you can open, whether AI agents may read them, agents online and the tools they run |
| `workspace_agents` | `workspace` | The workspace's agents: live state, version, the tools each one reports |
| `workspace_memory_dumps` | `workspace` | Memory dumps on the engram agents, and which ones are indexed. Asks every agent: allow a few seconds |
| `workspace_memory_index` | `workspace`, `agent`, `dump` | Starts indexing a dump on its host, in the background. Follow it with `workspace_memory_dumps` |
| `workspace_memory_overview` | `workspace`, `agent`, `dump` | A dump's index: system, process tree, findings (injected code and other anomalies), registry hives |
| `workspace_memory_process` | `workspace`, `agent`, `dump`, `pid` | One process in full: command line, environment, modules, memory regions, handles, findings |
| `workspace_memory_read` | `workspace`, `agent`, `dump`, `address`, `len?`, `space?`, `pid?` | Up to 4 KiB read live from the dump, as hex and text. `space` is `virtual` (needs `pid`, the default) or `physical` |
| `workspace_memory_registry` | `workspace`, `agent`, `dump`, `hive`, `path?` | One registry key: values, subkeys, last write time |
| `workspace_memory_yara` | `workspace`, `agent`, `dump`, `rules`, `pids?` | Runs YARA rules over the dump's processes on the host. Usually returns a job, a new one each call |
| `workspace_memory_yara_status` | `workspace`, `agent`, `job` | Progress of a YARA scan, and its matches once done |

**Kubernetes clusters (k3sec)**

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `workspace_cluster_list` | `workspace` | Clusters reporting to the workspace: nodes online, images, vulnerabilities in packages really loaded, recent detections |
| `workspace_cluster_images` | `workspace`, `cluster` | Running images with their vulnerabilities, loaded ones first |
| `workspace_cluster_image` | `workspace`, `cluster`, `digest` | One image: findings and packages, with which are loaded in memory |
| `workspace_cluster_events` | `workspace`, `cluster`, `source?`, `kind?`, `namespace?`, `min_severity?`, `q?`, `before?`, `limit?` | Runtime events, newest first: Kubernetes events, eBPF activity, YARA detections, with cached reputation of destinations and binaries. 200 at most per call; `before` pages back |
| `workspace_cluster_config` | `workspace`, `cluster` | What k3sec collects on each node, and the ceiling the nodes' local policies allow |

**Proxmox VE (virtsec)**

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `workspace_virt_list` | `workspace` | Proxmox clusters: nodes online, LXC and VM guests, guests with weakened isolation, vulnerabilities in loaded packages, critical events of the last 24 h |
| `workspace_virt_guests` | `workspace`, `cluster` | Guests and nodes: status, isolation risks from their config (privileged, host bind mounts, passthrough), vulnerabilities |
| `workspace_virt_guest` | `workspace`, `cluster`, `key`, `agent?` | One guest by vmid, or a node (`key` = `node` with its `agent`): isolation risks, findings, packages |
| `workspace_virt_events` | `workspace`, `cluster`, `source?`, `kind?`, `min_severity?`, `q?`, `vmid?`, `before?`, `limit?` | Runtime events, newest first: executions in guests, outbound connections, sensitive writes, VM escape signals, PVE logins, auth failures, tasks, guest config changes. 200 at most per call |
| `workspace_virt_config` | `workspace`, `cluster` | What virtsec collects on each node, and the ceiling the local policies allow |
| `workspace_virt_audit` | `workspace`, `cluster` | Security posture per node: failed checks (PVE firewall off, users without a second factor, root SSH with a password, unreachable or test repositories, guests without backup, isolation risks, pending restarts), each with a fix |

### Account, bookmarks and history

| Tool | Parameters | What it returns |
| --- | --- | --- |
| `get_account_info` | none | The authenticated user, their organization and plan |
| `get_scan_limits` | none | Remaining IP, domain, file and crypto quotas of the organization, over a rolling 24 hours shared by all members |
| `get_scan_history` | `type?`, `limit?` | Recent scans of the account, filtered by `ip`, `domain` or `file` |
| `get_bookmarks` | `limit?` | Your bookmarked indicators |
| `add_bookmark` | `value` | Bookmarks an IP, domain, URL, hash, crypto address, email, phone number or MAC address |
| `remove_bookmark` | `value` | Removes a bookmark |

## Authentication

OAuth 2.1 is the recommended path: authorization code with PKCE S256, dynamic client registration, CIMD supported. The server advertises its metadata at `https://mlab.sh/.well-known/oauth-authorization-server`, so a compliant client only needs the endpoint URL. A token issued this way is listed in Account > Settings as **OAuth: &lt;client name&gt;**; reconnecting the same client replaces its previous token instead of piling up new ones.

If your client does not speak OAuth, create a static token in Account > Settings > MCP Tokens and send it as `Authorization: Bearer mcp_xxx`. At creation you pick its lifetime: 30, 90 or 365 days, or never. A token can be renamed and revoked at any time from the same page.

MCP tokens are personal: they act as you, with your role in the organization. Organization API key permissions do not apply to them. Up to 5 active tokens, 100 on Team and Enterprise.

Full details: https://doc.mlab.sh/docs/mlab.sh/integrations/mcp

## Rate limits and quotas

Limits follow your organization's plan and are counted over a rolling 24 hour window, shared by every member. A spent quota returns an error that says which one and when it frees up. Call `get_scan_limits` to read what is left.

## Registry

Published to the official MCP Registry as `sh.mlab/mcp`.

https://registry.modelcontextprotocol.io/v0.1/servers?search=sh.mlab

## Other public servers

`https://news.mlab.sh/mcp` is a separate, unauthenticated, read only MCP server exposing a cyber news index. It is not published from this repo.

## Security

Report vulnerabilities to security@mlab.sh. See https://mlab.sh/security.txt and [SECURITY.md](SECURITY.md).

## License

MIT, see [LICENSE](LICENSE).
