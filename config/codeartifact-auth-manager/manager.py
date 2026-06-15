#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "codeartifact-auth-manager"
STATE_FILE = CONFIG_DIR / "state.json"
CONFIG_FILE = CONFIG_DIR / "config.json"

# The token is written into the files each tool re-reads on every invocation, so
# no shell or GUI app can ever hold a stale token. Static (credential-free)
# config lives in the tools' native config files; the rotating token lives only
# in ~/.netrc (pip + uv) and ~/.cargo/credentials.toml (cargo).
PIP_CONF = Path.home() / ".config" / "pip" / "pip.conf"
UV_CONFIG = Path.home() / ".config" / "uv" / "uv.toml"
CARGO_CONFIG = Path.home() / ".cargo" / "config.toml"
CARGO_CREDENTIALS = Path.home() / ".cargo" / "credentials.toml"
NETRC = Path.home() / ".netrc"


def load_config():
    """Load deployment-specific identifiers (account id, domain, region, profiles).

    Resolution order per key: environment variable, then config.json, then a
    default for the non-sensitive ones. The sensitive identifiers (domain,
    domain owner / AWS account id, repository) have no defaults and must be
    supplied locally, which keeps them out of the (public) dotfiles repo.
    See config.example.json for the expected shape.
    """
    file_cfg = {}
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE) as f:
                file_cfg = json.load(f)
        except (json.JSONDecodeError, IOError):
            file_cfg = {}

    def get(key, default=None):
        return os.environ.get(key) or file_cfg.get(key) or default

    cfg = {
        "domain": get("CA_DOMAIN"),
        "domain_owner": get("CA_DOMAIN_OWNER"),
        "repository": get("CA_REPOSITORY"),
        "region": get("CA_REGION", "us-east-2"),
        "sso_profile": get("CA_SSO_PROFILE", "dev"),
        "artifacts_profile": get("CA_ARTIFACTS_PROFILE", "artifacts"),
        # Cargo registry alias as referenced in repos ([registries.uni]).
        "cargo_registry": get("CA_CARGO_REGISTRY", "uni"),
    }

    missing = [
        env_key
        for env_key, cfg_key in (
            ("CA_DOMAIN", "domain"),
            ("CA_DOMAIN_OWNER", "domain_owner"),
            ("CA_REPOSITORY", "repository"),
        )
        if not cfg[cfg_key]
    ]
    if missing:
        print(
            f"[ERROR] Missing CodeArtifact config: {', '.join(missing)}. "
            f"Set them in {CONFIG_FILE} or as environment variables "
            f"(see config.example.json).",
            file=sys.stderr,
        )
        sys.exit(2)

    # CodeArtifact host and the credential-free index URLs derived from it.
    cfg["host"] = (
        f"{cfg['domain']}-{cfg['domain_owner']}.d.codeartifact."
        f"{cfg['region']}.amazonaws.com"
    )
    cfg["pip_index"] = f"https://{cfg['host']}/pypi/{cfg['repository']}/simple/"
    # Cargo (Rust) registry sparse index, derived unless an override is provided.
    cfg["cargo_index"] = get("CA_CARGO_INDEX") or (
        f"sparse+https://{cfg['host']}/cargo/{cfg['repository']}/"
    )

    return cfg


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

def load_state():
    """Load the current state from the state file."""
    if not STATE_FILE.exists():
        return {"authenticated": False, "expires_at": None}

    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {"authenticated": False, "expires_at": None}


def save_state(authenticated, expires_at=None):
    """Save the current state. expires_at is an ISO-8601 string (or None)."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    state = {"authenticated": authenticated, "expires_at": expires_at}
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def _parse_expiry(s):
    dt = datetime.fromisoformat(s)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def is_authenticated():
    """Check if we're currently authenticated (token hasn't expired)."""
    state = load_state()
    if not state["authenticated"] or not state["expires_at"]:
        return False
    return datetime.now(timezone.utc) < _parse_expiry(state["expires_at"])


# ---------------------------------------------------------------------------
# Credential files
# ---------------------------------------------------------------------------

def _atomic_write(path, content, mode=0o644):
    """Write content to path atomically (temp file + rename) with the given mode."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    with open(tmp, "w") as f:
        f.write(content)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def _upsert_field(path, header, field, literal, mode):
    """Set `field = literal` under the given TOML section header, preserving every
    other section. `literal` is written verbatim, so the caller quotes strings and
    formats arrays. Creates the section if absent."""
    line = f"{field} = {literal}"
    text = path.read_text() if path.exists() else ""
    lines = text.splitlines()

    start = next((i for i, l in enumerate(lines) if l.strip() == header), None)
    if start is None:
        block = []
        if lines and lines[-1].strip() != "":
            block.append("")
        block += [header, line]
        _atomic_write(path, ("\n".join(lines + block)).strip("\n") + "\n", mode)
        return

    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].lstrip().startswith("["):
            end = j
            break

    field_re = re.compile(rf"\s*{re.escape(field)}\s*=")
    for k in range(start + 1, end):
        if field_re.match(lines[k]):
            lines[k] = line
            break
    else:
        lines.insert(end, line)

    _atomic_write(path, "\n".join(lines).rstrip("\n") + "\n", mode)


def _update_netrc(host, login, token):
    """Replace the entry for `host` in ~/.netrc, preserving all other entries.

    Parses the standard machine/default token grammar (macdef macros are not
    supported and would need manual handling)."""
    text = NETRC.read_text() if NETRC.exists() else ""
    toks = text.split()
    keys = {"login", "password", "account", "port"}
    entries = []
    i, n = 0, len(toks)
    while i < n:
        t = toks[i]
        if t in ("machine", "default"):
            name = None
            if t == "machine" and i + 1 < n:
                name = toks[i + 1]
                i += 2
            else:
                i += 1
            fields = []
            while i < n and toks[i] not in ("machine", "default", "macdef"):
                if toks[i] in keys and i + 1 < n:
                    fields.append((toks[i], toks[i + 1]))
                    i += 2
                else:
                    i += 1
            entries.append((t, name, fields))
        else:
            i += 1

    lines = []
    for kind, name, fields in entries:
        if kind == "machine" and name == host:
            continue
        parts = ["machine", name] if kind == "machine" else ["default"]
        for k, v in fields:
            parts += [k, v]
        lines.append(" ".join(parts))
    lines.append(f"machine {host} login {login} password {token}")
    _atomic_write(NETRC, "\n".join(lines) + "\n", 0o600)


def ensure_static_configs(cfg):
    """Write the credential-free, non-rotating config into each tool's native file."""
    _atomic_write(
        PIP_CONF,
        f"[global]\nindex-url = {cfg['pip_index']}\n"
        f"extra-index-url = https://pypi.org/simple\n",
        0o644,
    )
    _atomic_write(
        UV_CONFIG,
        f'index-url = "{cfg["pip_index"]}"\n'
        f'extra-index-url = ["https://pypi.org/simple"]\n',
        0o644,
    )
    _upsert_field(
        CARGO_CONFIG,
        f"[registries.{cfg['cargo_registry']}]",
        "index",
        f'"{cfg["cargo_index"]}"',
        0o644,
    )
    # Authenticated sparse registries require an explicit credential provider;
    # cargo:token reads the token from ~/.cargo/credentials.toml.
    _upsert_field(
        CARGO_CONFIG,
        "[registry]",
        "global-credential-providers",
        '["cargo:token"]',
        0o644,
    )


# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

def get_token(cfg):
    """Fetch a CodeArtifact token using the existing SSO session. Never opens a
    browser. Returns (token, expiration_iso) or (None, None) if the SSO session
    has expired (the AWS CLI silently refreshes via the refresh token otherwise)."""
    result = subprocess.run(
        [
            "aws", "codeartifact", "get-authorization-token",
            "--domain", cfg["domain"],
            "--domain-owner", cfg["domain_owner"],
            "--region", cfg["region"],
            "--output", "json",
        ],
        env={
            "AWS_PROFILE": cfg["artifacts_profile"],
            "PATH": os.environ["PATH"],
            "HOME": os.environ["HOME"],
        },
        capture_output=True,
        text=True,
    )

    if result.returncode != 0 or not result.stdout.strip():
        print(
            f"[INFO] Browser-free refresh unavailable (SSO session likely expired): "
            f"{result.stderr.strip()}",
            file=sys.stderr,
        )
        return None, None

    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("[ERROR] Could not parse get-authorization-token output", file=sys.stderr)
        return None, None

    token = data.get("authorizationToken")
    if not token:
        return None, None

    exp = data.get("expiration")
    if isinstance(exp, (int, float)):
        exp = datetime.fromtimestamp(exp, timezone.utc).isoformat()
    return token, exp


def refresh_codeartifact(cfg):
    """Browser-free refresh: fetch one token and write it into every tool's files."""
    token, expiration = get_token(cfg)
    if not token:
        return False

    ensure_static_configs(cfg)
    _update_netrc(cfg["host"], "aws", token)
    _upsert_field(
        CARGO_CREDENTIALS,
        f"[registries.{cfg['cargo_registry']}]",
        "token",
        f'"{token}"',
        0o600,
    )
    save_state(authenticated=True, expires_at=expiration)
    return True


def notify(title, message, action=None):
    """Best-effort macOS notification. With terminal-notifier and an action command,
    the notification runs that command when clicked; otherwise it falls back to a
    plain (non-clickable) osascript notification."""
    tn = shutil.which("terminal-notifier")
    if not tn and os.path.exists("/opt/homebrew/bin/terminal-notifier"):
        tn = "/opt/homebrew/bin/terminal-notifier"
    if tn and action:
        try:
            subprocess.run(
                [tn, "-title", title, "-message", message, "-execute", action],
                capture_output=True, text=True,
            )
            return
        except Exception:
            pass
    try:
        subprocess.run(
            ["osascript", "-e",
             f'display notification "{message}" with title "{title}"'],
            capture_output=True, text=True,
        )
    except Exception:
        pass


def signin_action():
    """Shell command that runs a foreground sign-in, with a PATH that resolves uv
    and aws. Used as the click action of the expiry notification."""
    paths = f"/opt/homebrew/bin:{Path.home() / '.local' / 'bin'}:/usr/bin:/bin"
    return f'PATH={paths} {CONFIG_DIR / "manager.py"} refresh'


def sso_login(cfg):
    """Run an interactive AWS SSO login (opens the default browser in the foreground).

    Only used on the manual / click path, where the user has chosen to sign in, so a
    foreground browser is expected. The scheduled path never opens a browser, because
    a Chromium-based default browser pulls itself to the foreground regardless of the
    macOS background-open flag, so we cannot guarantee it stays out of the way.
    """
    result = subprocess.run(
        ["aws", "sso", "login", "--profile", cfg["sso_profile"]],
        text=True,
    )
    return result.returncode == 0


def authenticate(interactive=False):
    """Refresh credentials, browser-free whenever the SSO session is still alive.

    If the SSO session has expired, behavior depends on the caller:
      - interactive=True (manual / click): open a foreground SSO login, then refresh.
      - interactive=False (scheduled): open nothing. Post a notification and leave the
        state unauthenticated so the Sketchybar checkbox empties; the user signs in on
        their own terms via the menu bar item or ca-auth.
    """
    try:
        cfg = load_config()

        if refresh_codeartifact(cfg):
            print("[SUCCESS] CodeArtifact refreshed without a browser")
            return True

        if not interactive:
            print("[INFO] SSO session expired; notifying (no browser opened).")
            save_state(authenticated=False)
            notify("CodeArtifact", "Token expired", action=signin_action())
            return False

        print("[INFO] SSO session expired; opening browser for login...")
        if not sso_login(cfg):
            print("[ERROR] AWS SSO login failed", file=sys.stderr)
            save_state(authenticated=False)
            return False

        if refresh_codeartifact(cfg):
            print("[SUCCESS] CodeArtifact authentication complete")
            return True

        print("[ERROR] CodeArtifact refresh failed after SSO login", file=sys.stderr)
        save_state(authenticated=False)
        return False

    except Exception as e:
        print(f"[ERROR] Authentication failed: {e}", file=sys.stderr)
        return False


def status():
    """Check and print the current authentication status."""
    if is_authenticated():
        state = load_state()
        time_left = _parse_expiry(state["expires_at"]) - datetime.now(timezone.utc)
        hours = int(time_left.total_seconds() / 3600)
        minutes = int((time_left.total_seconds() % 3600) / 60)
        print(f"Authenticated (expires in {hours}h {minutes}m)")
        return True
    print("Not authenticated")
    return False


def check_and_refresh():
    """Check if authenticated, silently refresh if the SSO session allows it.

    Never opens a browser; if a browser is needed, leaves the state unauthenticated
    for the scheduled job (auto) or a manual click (refresh) to handle.
    """
    if is_authenticated():
        return True

    print("[INFO] Token expired; attempting browser-free refresh...")
    return refresh_codeartifact(load_config())


def main():
    usage = "Usage: manager.py {status|refresh|auto|check}"
    if len(sys.argv) < 2:
        print(usage)
        sys.exit(1)

    command = sys.argv[1]

    if command == "status":
        success = status()
        sys.exit(0 if success else 1)

    elif command == "refresh":
        # Manual / click-triggered: silent if possible, else foreground browser.
        success = authenticate(interactive=True)
        sys.exit(0 if success else 1)

    elif command == "auto":
        # Scheduled: silent if possible, else notify (no browser).
        success = authenticate(interactive=False)
        sys.exit(0 if success else 1)

    elif command == "check":
        success = check_and_refresh()
        sys.exit(0 if success else 1)

    else:
        print(f"Unknown command: {command}")
        print(usage)
        sys.exit(1)


if __name__ == "__main__":
    main()
