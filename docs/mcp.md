# MCP servers

MCP tools consume model context even when idle, so the default set is small.
Servers that are configured but disabled do not connect and do not add tools.

## Default OpenCode set

Defined in `opencode/opencode.jsonc` under `mcp.servers` (V2 shape):

| Server | Transport | Default | Notes |
|---|---|---|---|
| `engram` | stdio: `engram mcp --tools=agent` | enabled | shared persistent memory |
| `codegraph` | stdio: `codegraph serve --mcp` | enabled | per-project code index |
| `context7` | HTTP `https://mcp.context7.com/mcp` | enabled | documentation lookup |
| `playwright` | stdio: `playwright-mcp` | disabled | enable for browser tests |
| `chrome-devtools` | stdio: `chrome-devtools-mcp` | disabled | needs Chrome/Chrome for Testing |
| `github` | HTTP `https://api.githubcopilot.com/mcp/` | disabled | OAuth |
| `sentry` | HTTP `https://mcp.sentry.dev/mcp` | disabled | OAuth |
| `supabase` | HTTP `https://mcp.supabase.com/mcp` | disabled | OAuth |

Enable one by setting `"disabled": false`, then run `nex link` and restart
OpenCode. Remote servers use OAuth by default; credentials are stored outside the
config file.

```bash
opencode mcp list
opencode mcp auth sentry
```

Inside the TUI, `/mcps` shows status and starts the browser consent flow.

## Claude Code

Engram is registered by `engram setup claude-code`. The remaining servers are
registered by:

```bash
bash ~/nex/scripts/install-mcp.sh          # engram, codegraph, playwright, context7
bash ~/nex/scripts/install-mcp.sh --all    # also github, sentry, supabase, chrome-devtools
claude mcp list
```

The script is idempotent: it skips a server that is already registered. OAuth
consent happens in Claude Code with `/mcp`.

Claude Code stores MCP server definitions in `~/.claude.json` (user scope), not
in `settings.json`. That is why the repository does not symlink an MCP file for
Claude.

## Context budget

- Start with engram + codegraph + context7. Add others only for the task.
- Prefer a project-scoped server over a global one when only one repository
  needs it.
- In OpenCode, `codemode: false` is used for engram and codegraph so their tools
  are direct rather than grouped through Code Mode.
- Claude Code subagents can receive MCP servers through their `mcpServers`
  frontmatter; that keeps the parent context clean. The generated agents do not
  do this by default.

## Adding a server

OpenCode:

```jsonc
"mcp": {
  "servers": {
    "my-server": {
      "type": "local",
      "command": ["my-server", "--mcp"],
      "disabled": false
    }
  }
}
```

Remote:

```jsonc
"my-remote": {
  "type": "remote",
  "url": "https://example.com/mcp"
}
```

Claude:

```bash
claude mcp add --scope user my-server -- my-server --mcp
claude mcp add --scope user --transport http my-remote https://example.com/mcp
```

Do not put secrets in `opencode.jsonc`. Use `{env:NAME}` or the OAuth flow. See
`docs/security.md`.

## Known issues

- `engram setup opencode` (Engram 3.6.1) writes a V1-style
  `~/.config/opencode/opencode.json` with `mcp.engram` and `enabled`. OpenCode V2
  expects `mcp.servers.engram`. `nex link` backs that file up and removes it.
  Re-running `engram setup` recreates it; run `nex link` again.
- Chrome DevTools MCP supports Chrome/Chrome for Testing, not Chromium. Install
  Chrome for Testing with `scripts/install-browsers.sh --with-chrome` and pass
  `--executablePath` if it is not found.
- Remote MCP OAuth may require a browser and cannot be completed from the agent
  shell.
