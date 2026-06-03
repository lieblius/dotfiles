# CodeArtifact Auth Manager

Automatic AWS CodeArtifact authentication manager with Sketchybar integration.

## Features

- No browser opening on shell startup
- Automatic token refresh only when expired (12-hour expiry)
- Global environment variables across all shells
- Sketchybar visual indicator
- Click-to-authenticate

## Architecture

### Components

1. **manager.py** - Python script (uses uv) that manages authentication
2. **config.json** - Deployment-specific identifiers (account id, domain, region). Local only, gitignored. Copy from `config.example.json`.
3. **env.sh** - Shell script with environment variables (auto-generated). Local only, gitignored.
4. **state.json** - Stores authentication state and expiry time. Local only, gitignored.
5. **Sketchybar plugins** - Display auth status and handle clicks

### Configuration

The company-specific identifiers are not committed. On a new machine, copy the
example and fill in real values:

```bash
cp config.example.json ~/.config/codeartifact-auth-manager/config.json
# then edit config.json with the real domain / account id / repo
```

Each key may also be supplied as an environment variable (`CA_DOMAIN`,
`CA_DOMAIN_OWNER`, `CA_REPOSITORY`, `CA_REGION`, `CA_SSO_PROFILE`,
`CA_ARTIFACTS_PROFILE`, optional `CA_CARGO_INDEX`); environment variables take
precedence over `config.json`. `CA_DOMAIN`, `CA_DOMAIN_OWNER`, and
`CA_REPOSITORY` are required; the rest have sensible defaults. The cargo sparse
index is derived from these values unless `CA_CARGO_INDEX` overrides it.

`manager.py status` (the 60s Sketchybar poll) reads only `state.json`, so the
indicator keeps working even before `config.json` is set up.

### Environment Variables Set

When authenticated, these variables are available in all shells:

- `DEVPI_URL` - Full pip index URL with credentials
- `UV_DEFAULT_INDEX` - Default index for uv
- `UV_PUBLISH_USERNAME` - Username for publishing
- `UV_PUBLISH_PASSWORD` - Password for publishing
- `UV_PUBLISH_URL` - Publishing URL
- `CARGO_REGISTRIES_UNI_INDEX` - Cargo sparse index URL
- `CARGO_REGISTRIES_UNI_TOKEN` - Cargo Bearer token (raw CodeArtifact token)
- `CARGO_REGISTRIES_UNI_CREDENTIAL_PROVIDER` - `cargo:token`

## Usage

### Status Check

```bash
ca-status
```

Shows current authentication status and time remaining.

### Manual Authentication

```bash
ca-auth
```

Forces re-authentication and loads environment variables in current shell.

### Sketchybar

- Filled checkbox - Authenticated
- Empty checkbox - Not authenticated
- Click the indicator to authenticate
- Updates every 60 seconds

### Shell Integration

Environment variables are automatically loaded when you start a new shell session.
No browser opens unless you explicitly trigger authentication (via alias or Sketchybar click).

## Files

- `~/.config/codeartifact-auth-manager/manager.py` - Main script (tracked)
- `~/.config/codeartifact-auth-manager/config.example.json` - Config template (tracked)
- `~/.config/codeartifact-auth-manager/config.json` - Real identifiers (local only)
- `~/.config/codeartifact-auth-manager/env.sh` - Environment variables (local only)
- `~/.config/codeartifact-auth-manager/state.json` - Authentication state (local only)
- `~/.config/sketchybar/plugins/codeartifact.sh` - Status display plugin
- `~/.config/sketchybar/plugins/codeartifact_click.sh` - Click handler

## How It Works

1. Shell starts -> Sources `env.sh` (just loads existing vars, no auth)
2. Sketchybar polls every 60s -> Reads `state.json` to check expiry
3. Token expires -> Shows empty checkbox in Sketchybar
4. Click indicator -> Runs `manager.py refresh` -> Opens browser for AWS SSO
5. Authentication complete -> Updates `env.sh` and `state.json`
6. New shells -> Automatically have fresh environment variables
