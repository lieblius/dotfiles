#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import json
import os
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "codeartifact-auth-manager"
STATE_FILE = CONFIG_DIR / "state.json"
ENV_FILE = CONFIG_DIR / "env.sh"
CONFIG_FILE = CONFIG_DIR / "config.json"
PIP_CONF = Path.home() / ".config" / "pip" / "pip.conf"

# Token expires after 12 hours
TOKEN_EXPIRY_HOURS = 12


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

    # Cargo (Rust) registry sparse index, derived from the identifiers above
    # unless an explicit override is provided.
    cfg["cargo_index"] = get("CA_CARGO_INDEX") or (
        f"sparse+https://{cfg['domain']}-{cfg['domain_owner']}.d.codeartifact."
        f"{cfg['region']}.amazonaws.com/cargo/{cfg['repository']}/"
    )

    return cfg


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
    """Save the current state to the state file."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    state = {
        "authenticated": authenticated,
        "expires_at": expires_at.isoformat() if expires_at else None,
    }
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def is_authenticated():
    """Check if we're currently authenticated (token hasn't expired)."""
    state = load_state()
    if not state["authenticated"] or not state["expires_at"]:
        return False

    expires_at = datetime.fromisoformat(state["expires_at"])
    return datetime.now() < expires_at


def extract_pip_config():
    """Extract the index-url from pip.conf and return parsed components."""
    if not PIP_CONF.exists():
        return None

    try:
        with open(PIP_CONF) as f:
            content = f.read()

        # Find index-url line
        for line in content.split("\n"):
            if line.strip().startswith("index-url"):
                url = line.split("=", 1)[1].strip()

                # Parse URL: https://username:password@domain/path
                import re
                match = re.match(r'https://([^:]+):([^@]+)@(.+)/simple/?', url)
                if match:
                    username, password, domain_url = match.groups()
                    return {
                        "index_url": url,
                        "username": username,
                        "password": password,
                        "publish_url": f"https://{domain_url}",
                    }
        return None
    except IOError:
        return None


def get_cargo_token(cfg):
    """Fetch the raw CodeArtifact authorization token for cargo Bearer auth.

    The pip.conf password can't be reused since it may be URL-encoded.
    """
    result = subprocess.run(
        [
            "aws", "codeartifact", "get-authorization-token",
            "--domain", cfg["domain"],
            "--domain-owner", cfg["domain_owner"],
            "--region", cfg["region"],
            "--query", "authorizationToken",
            "--output", "text",
        ],
        env={"AWS_PROFILE": cfg["artifacts_profile"], "PATH": os.environ["PATH"]},
        capture_output=True,
        text=True,
    )

    if result.returncode != 0 or not result.stdout.strip():
        return None
    return result.stdout.strip()


def write_env_file(config, cargo_index, cargo_token=None):
    """Write environment variables to the env file."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)

    if config:
        content = f"""# CodeArtifact environment variables
# Auto-generated by codeartifact-auth-manager
export DEVPI_URL="{config['index_url']}"
export UV_DEFAULT_INDEX="{config['index_url']}"
export UV_PUBLISH_USERNAME="{config['username']}"
export UV_PUBLISH_PASSWORD="{config['password']}"
export UV_PUBLISH_URL="{config['publish_url']}"
"""
        if cargo_token:
            content += f"""
export CARGO_REGISTRIES_UNI_INDEX="{cargo_index}"
export CARGO_REGISTRIES_UNI_TOKEN="{cargo_token}"
export CARGO_REGISTRIES_UNI_CREDENTIAL_PROVIDER="cargo:token"
"""
    else:
        content = "# No CodeArtifact authentication available\n"

    with open(ENV_FILE, "w") as f:
        f.write(content)


def authenticate():
    """Perform AWS SSO login and CodeArtifact authentication."""
    try:
        cfg = load_config()

        # Step 1: AWS SSO login
        print("[INFO] Starting AWS SSO login...")
        result = subprocess.run(
            ["aws", "sso", "login", "--profile", cfg["sso_profile"]],
            capture_output=False,
            text=True,
        )

        if result.returncode != 0:
            print(f"[ERROR] AWS SSO login failed", file=sys.stderr)
            return False

        # Step 2: CodeArtifact login
        print("[INFO] Authenticating with CodeArtifact...")
        result = subprocess.run(
            [
                "aws", "codeartifact", "login",
                "--tool", "pip",
                "--repository", cfg["repository"],
                "--domain", cfg["domain"],
                "--domain-owner", cfg["domain_owner"],
                "--region", cfg["region"],
            ],
            env={"AWS_PROFILE": cfg["artifacts_profile"], "PATH": os.environ["PATH"]},
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print(f"[ERROR] CodeArtifact login failed: {result.stderr}", file=sys.stderr)
            return False

        # Step 3: Extract config and write env file
        config = extract_pip_config()
        if not config:
            print("[ERROR] Failed to extract pip config", file=sys.stderr)
            return False

        cargo_token = get_cargo_token(cfg)
        if not cargo_token:
            print("[WARN] Could not fetch cargo token; cargo vars omitted", file=sys.stderr)

        write_env_file(config, cfg["cargo_index"], cargo_token)

        # Step 4: Save state
        expires_at = datetime.now() + timedelta(hours=TOKEN_EXPIRY_HOURS)
        save_state(authenticated=True, expires_at=expires_at)

        print("[SUCCESS] CodeArtifact authentication complete")
        return True

    except Exception as e:
        print(f"[ERROR] Authentication failed: {e}", file=sys.stderr)
        return False


def status():
    """Check and print the current authentication status."""
    if is_authenticated():
        state = load_state()
        expires_at = datetime.fromisoformat(state["expires_at"])
        time_left = expires_at - datetime.now()
        hours = int(time_left.total_seconds() / 3600)
        minutes = int((time_left.total_seconds() % 3600) / 60)
        print(f"Authenticated (expires in {hours}h {minutes}m)")
        return True
    else:
        print("Not authenticated")
        return False


def check_and_refresh():
    """Check if authenticated, refresh if needed."""
    if is_authenticated():
        return True

    print("[INFO] Token expired or not authenticated, refreshing...")
    return authenticate()


def main():
    if len(sys.argv) < 2:
        print("Usage: manager.py {status|refresh|check}")
        sys.exit(1)

    command = sys.argv[1]

    if command == "status":
        success = status()
        sys.exit(0 if success else 1)

    elif command == "refresh":
        success = authenticate()
        sys.exit(0 if success else 1)

    elif command == "check":
        success = check_and_refresh()
        sys.exit(0 if success else 1)

    else:
        print(f"Unknown command: {command}")
        print("Usage: manager.py {status|refresh|check}")
        sys.exit(1)


if __name__ == "__main__":
    main()
