# debug-via-tailscale

SSH into GitHub Actions runners for interactive debugging — privately via your Tailscale network.

Inspired by: https://github.com/luchihoratiu/debug-via-ssh

## Quick Start

```yaml
name: Debug Runner
on: workflow_dispatch

jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - name: Debug via Tailscale
        uses: Sharpie/debug-via-tailscale@v1
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:github-actions
```

Then SSH from any machine on your tailnet using the connection info printed in the workflow logs.

## Prerequisites

1. **A Tailscale account** with a tailnet
2. **An OAuth client** — create one at Settings > Trust credentials with `auth_keys` scope
3. **ACL tags** — add `tag:github-actions` (or your chosen tag) to your ACL policy:
   ```json
   "tagOwners": {
     "tag:github-actions": ["autogroup:admin"]
   }
   ```
4. **Tailscale SSH ACLs** — allow SSH access to tagged nodes:
   ```json
   "ssh": [
     {
       "action": "accept",
       "src":    ["autogroup:admin"],
       "dst":    ["tag:github-actions"],
       "users":  ["autogroup:nonroot"]
     }
   ]
   ```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `oauth-client-id` | no* | — | Tailscale OAuth client ID |
| `oauth-secret` | no* | — | Tailscale OAuth client secret |
| `authkey` | no* | — | Tailscale auth key |
| `tags` | yes | `tag:github-actions` | ACL tags for the ephemeral node |
| `timeout` | no | `21500` | Max session duration in seconds (~6 hours) |
| `tailscale-args` | no | — | Extra arguments for `tailscale up` |

\*One auth method required: `oauth-client-id` + `oauth-secret`, or `authkey`.

## Authentication Methods

### OAuth Client (Recommended)

```yaml
with:
  oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
  oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
  tags: tag:github-actions
```

Create an OAuth client at **Settings > OAuth clients** in the Tailscale admin console. The client needs the `auth_keys` scope.

### Auth Key

```yaml
with:
  authkey: ${{ secrets.TS_AUTHKEY }}
  tags: tag:github-actions
```

Generate an auth key at **Settings > Keys**. Use a reusable, ephemeral key tagged with your CI tag.

## Examples

### Debug on workflow failure

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make build
      - run: make test

      - name: Debug on failure
        if: failure()
        uses: your-username/debug-via-tailscale@v1
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
```

### Manual debug trigger

```yaml
on:
  workflow_dispatch:
    inputs:
      debug:
        description: 'Enable SSH debugging'
        type: boolean
        default: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make build

      - name: Debug session
        if: inputs.debug
        uses: your-username/debug-via-tailscale@v1
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          timeout: '3600'
```

## Supported Runners

- **Linux** (ubuntu-latest, ubuntu-22.04, etc.) — full support
- **macOS** (macos-latest, macos-14, etc.) — full support
- **Windows** — not yet supported

## How It Works

1. Validates that an authentication method is provided
2. Connects the runner to your Tailscale network using [tailscale/github-action](https://github.com/tailscale/github-action) with Tailscale SSH enabled
3. Displays the runner's Tailscale IP and DNS name in the workflow logs
4. Waits until the timeout expires or you create `~/continue` to end the session early

The runner joins as an ephemeral node and is automatically removed when the workflow ends.

## Ending a Session

From inside your SSH session, run:

```
touch ~/continue
```

This signals the action to proceed, ending the debug session and continuing the workflow.
