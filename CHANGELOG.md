# Changelog

All notable changes to this registry listing are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-11-05

### Added

- Cases tools in the README: `list_cases`, `get_case`, `create_case`, `add_case_indicators`, `add_case_comment`.
- The 21 `workspace_*` tools (memory dumps, Kubernetes clusters, Proxmox VE), and how `tools/list` filters tools by role, plan and per-workspace MCP access.
- Parameters of every tool, taken from the server's definitions, with optional ones marked.
- A plan and role table: cases need Team or Enterprise, workspaces Team (1) or Enterprise (up to 20), viewers can read but not spend quota or write to cases.
- Static MCP tokens: lifetime chosen at creation (30, 90 or 365 days, or never), renaming, 5 active tokens or 100 on Team and Enterprise. OAuth grants show as **OAuth: &lt;client name&gt;** and a reconnect replaces the previous token.

### Changed

- README tool list matches the server: 48 tools, grouped as IOC lookups, domain scans and code, CVEs and actors, cases, workspaces, account. Which lookups spend quota is stated per tool.
- Quotas described as per organization over a rolling 24 hours.
- `server.json`: version 1.0.1, description covers domain scans, cases, memory forensics, Kubernetes and Proxmox.

### Removed

- `smishing_risk`, `actors_by_cve` and `hello_world` from the README: the server no longer exposes them.

## [1.0.0] - 2026-08-31

### Added

- Initial registry listing.
