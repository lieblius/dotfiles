# CodeArtifact Auth Manager

Automatic AWS CodeArtifact authentication for pip, uv, and cargo, with a
Sketchybar indicator.

## Features

- No browser opening on shell startup
- Scheduled refresh at 09:00 and 21:00 via launchd, browser-free in the common case
- A browser is never opened automatically. When the underlying SSO session expires
  (~weekly), the scheduled job posts a notification and empties the menu bar item;
  you sign in on your own terms, so your focus is never stolen
- Credentials written to each tool's own config files, re-read on every
  invocation, so no shell (however old) and no GUI app can ever hold a stale token
- Sketchybar visual indicator
- Click-to-authenticate

### Two tokens, one browser

There are two separate tokens at play, and only one of them needs a browser:

- The SSO session token in `~/.aws/sso/cache/`. Obtaining it requires the
  browser-based AWS SSO login. With the modern `sso-session` config it carries a
  refresh token, so it silently renews for the duration of the SSO session
  (roughly a week) without any browser.
- The 12h CodeArtifact token, derived from the SSO session token. Refreshing it
  needs no browser at all, as long as the SSO session is still alive.

So the routine 12h refresh is always browser-free. The browser is only needed
the rare time the whole SSO session expires.

### How credentials reach your tools

The rotating token is never exported as an environment variable. Environment
variables are a snapshot taken at shell start, so a long-lived shell would keep a
stale token after a rotation. Instead the token is written into the files each
tool re-reads on every invocation:

- `~/.netrc` - one entry for the CodeArtifact host, used by both pip and uv
- `~/.cargo/credentials.toml` - the `[registries.uni]` token, used by cargo

The static, credential-free configuration (index URLs, the cargo registry and
its credential provider) lives in each tool's native config file and never
rotates:

- `~/.config/pip/pip.conf` - credential-free `index-url`
- `~/.config/uv/uv.toml` - credential-free default index
- `~/.cargo/config.toml` - `[registries.uni]` index plus
  `global-credential-providers = ["cargo:token"]`

Because the secret lives only in files that are re-read per run, refreshing is
just a matter of rewriting two files; nothing in any running shell needs to
change. This also covers GUI apps (e.g. PyCharm) that never source your shell.

## Architecture

### Components

1. **manager.py** - Python script (uses uv) that fetches the token and writes it into the credential files
2. **config.json** - Deployment-specific identifiers (account id, domain, region). Local only, gitignored. Copy from `config.example.json`.
3. **state.json** - Stores authentication state and the real token expiry. Local only, gitignored.
4. **Sketchybar plugins** - Display auth status and handle clicks
5. **com.liebl.codeartifact-refresh.plist** - launchd agent that runs `manager.py auto` at 09:00 and 21:00

### Commands

`manager.py` accepts:

- `status` - print auth status and time remaining (reads only `state.json`)
- `refresh` - manual/click refresh; silent if the SSO session is alive, otherwise a foreground browser login
- `auto` - scheduled refresh; silent if the SSO session is alive, otherwise a background browser login
- `check` - silent refresh only; never opens a browser

### Configuration

The company-specific identifiers are not committed. On a new machine, copy the
example and fill in real values:

```bash
cp config.example.json ~/.config/codeartifact-auth-manager/config.json
# then edit config.json with the real domain / account id / repo
```

Each key may also be supplied as an environment variable (`CA_DOMAIN`,
`CA_DOMAIN_OWNER`, `CA_REPOSITORY`, `CA_REGION`, `CA_SSO_PROFILE`,
`CA_ARTIFACTS_PROFILE`, `CA_CARGO_REGISTRY`, optional `CA_CARGO_INDEX`);
environment variables take precedence over `config.json`. `CA_DOMAIN`,
`CA_DOMAIN_OWNER`, and `CA_REPOSITORY` are required; the rest have sensible
defaults (`CA_CARGO_REGISTRY` defaults to `uni`). The pip/uv index and cargo
sparse index are derived from these values.

`manager.py status` (the 60s Sketchybar poll) reads only `state.json`, so the
indicator keeps working even before `config.json` is set up.

### Files written by the manager

Rotated on every refresh (mode 600):

- `~/.netrc` - CodeArtifact host entry (surgical: only that machine line is touched)
- `~/.cargo/credentials.toml` - `[registries.uni] token` (surgical: only that block)

Written once / kept in sync (mode 644, no secrets):

- `~/.config/pip/pip.conf`
- `~/.config/uv/uv.toml`
- `~/.cargo/config.toml`

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

Refreshes the credential files. Silent (no browser) whenever the SSO session is
still alive; only opens a browser if the SSO session has fully expired. There is
nothing to re-source afterwards; tools pick up the new token on their next run.

### Scheduled Refresh (launchd)

The `com.liebl.codeartifact-refresh` agent runs `manager.py auto` at 09:00 and
21:00 daily (a run missed while the machine is asleep fires on wake). It refreshes
the token using the existing SSO session, with no browser. It never opens a browser
on its own: if the SSO session itself has expired, it posts a macOS notification and
leaves the Sketchybar checkbox empty, and you sign in when you choose (click the
checkbox or run `ca-auth`), which opens a foreground login in your default browser.

Auto-opening a background browser was tried and dropped: a Chromium-based default
browser (e.g. Comet) pulls itself to the foreground on every URL open regardless of
the macOS background flag, so a clean background login could not be guaranteed.

Manage it with:

```bash
# load (first install)
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.liebl.codeartifact-refresh.plist
# run once now
launchctl kickstart -p gui/$(id -u)/com.liebl.codeartifact-refresh
# unload
launchctl bootout gui/$(id -u)/com.liebl.codeartifact-refresh
# logs
cat /tmp/com.liebl.codeartifact-refresh.std{out,err}.log
```

### Sketchybar

- Filled checkbox - Authenticated
- Empty checkbox - Not authenticated
- Click the indicator to authenticate
- Updates every 60 seconds

### Publishing

`uv publish` to CodeArtifact authenticates against the same host, so it uses the
`~/.netrc` entry. If a publish ever needs an explicit token, run `ca-auth` first
to ensure the files are fresh.

## Files

- `~/.config/codeartifact-auth-manager/manager.py` - Main script (tracked)
- `~/.config/codeartifact-auth-manager/config.example.json` - Config template (tracked)
- `~/.config/codeartifact-auth-manager/config.json` - Real identifiers (local only)
- `~/.config/codeartifact-auth-manager/state.json` - Authentication state (local only)
- `~/.config/codeartifact-auth-manager/com.liebl.codeartifact-refresh.plist` - launchd agent (tracked; symlinked into `~/Library/LaunchAgents/`)
- `~/.config/sketchybar/plugins/codeartifact.sh` - Status display plugin
- `~/.config/sketchybar/plugins/codeartifact_click.sh` - Click handler

## How It Works

1. Sketchybar polls every 60s -> reads `state.json` to check expiry
2. launchd runs `manager.py auto` at 09:00 and 21:00 -> fetches one CodeArtifact
   token from the existing SSO session (no browser) and writes it into `~/.netrc`
   and `~/.cargo/credentials.toml`
3. If the SSO session has expired -> `auto` posts a notification, leaves the state
   unauthenticated, and opens nothing
4. Token expires or SSO session is dead -> Sketchybar shows the empty checkbox
5. Click indicator -> runs `manager.py refresh` -> silent if the SSO session is
   alive, otherwise a foreground browser login
6. pip, uv, and cargo read the credential files fresh on every invocation, so any
   shell or GUI app always uses the current token without re-sourcing anything
