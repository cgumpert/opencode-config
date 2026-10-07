# opencode global config

Git repository holding my global [OpenCode](https://opencode.ai) configuration.
Checking it out puts a new OpenCode installation into the same state as this
machine.

## Checkout location (important)

The repository **must** be checked out at:

```text
~/.config/opencode
```

That is the directory OpenCode reads for global (per-user, all-projects)
configuration. If `$XDG_CONFIG_HOME` is set, OpenCode reads
`$XDG_CONFIG_HOME/opencode` instead, so in that case check out to
`$XDG_CONFIG_HOME/opencode`.

Clone it there:

```sh
git clone git@github.com:cgumpert/opencode-config.git ~/.config/opencode
```

If the directory already exists (a fresh machine often has one), either clone
into a temp dir and move the files in, or init and pull:

```sh
cd ~/.config/opencode
git init
git remote add origin git@github.com:cgumpert/opencode-config.git
git pull --rebase origin main
```

Both examples use SSH, which requires the machine's GitHub key to be set up
already. If you prefer HTTPS, use
`https://github.com/cgumpert/opencode-config.git` instead — GitHub accepts the
URL with or without the trailing `.git` — and let your GitHub credential helper
handle authentication. Never put a token in this repository.

A wrong checkout path means OpenCode silently uses its defaults — nothing
errors, your settings just don't apply.

## What's in here

| Path | Purpose |
| --- | --- |
| `opencode.jsonc` | Global server/project config: plugins, model, permissions, agents, MCP, skills, … JSONC, so it may contain `//` comments. |
| `cli.json` | Terminal-only preferences: theme, keybindings, sessions, tabs. Never put these in `opencode.jsonc`. Plain JSON only — OpenCode documents `cli.json`, not a `.jsonc` variant. |
| `commands/*.md` | Custom slash commands. |

## What is deliberately not in here

- **`service.json`** — gitignored. Contains the local background service's
  auth password, regenerated per machine. OpenCode recreates it on first run.
- **`~/.local/share/opencode/`** — database, logs, snapshots, shell state.
  Runtime data, never config.
- **`~/.config/opencode/auth*` and credentials** — OAuth tokens and API keys
  are stored outside this repository. Reference secrets as `{env:NAME}` in
  config instead of writing literal values.

`.git/hooks/pre-commit` blocks commits containing anything that looks like a
credential. Hooks are not versioned by git, so after a fresh clone re-install
it:

```sh
cd ~/.config/opencode
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
# Refuse to commit anything that looks like a credential.
fail=0
for f in "$@"; do
  [ -f "$f" ] || continue
  if grep -nEi '(sk-[A-Za-z0-9_-]{16,}|(api[_-]?key|secret|password|token)["'"'"']?[[:space:]]*[:=][[:space:]]*"[^"]{12,})' "$f"; then
    echo "pre-commit: possible secret in $f (shown above)" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || { echo "Commit blocked. Move the value to an {env:NAME} reference or drop the file." >&2; exit 1; }
exit 0
EOF
chmod +x .git/hooks/pre-commit
```

## Verifying the installation

```sh
cd ~/.config/opencode
git status            # clean tree, service.json absent
ls                    # opencode.jsonc cli.json commands/
```

Then start OpenCode and check that your commands and plugin load. To confirm
OpenCode actually discovered the config file (a typo in the filename fails
silently), list the configuration sources:

```sh
opencode debug config
```

The output should include a `document` entry whose `path` is
`~/.config/opencode/opencode.jsonc`. If it is missing, check the path and the
filename. Other failures to check for:

```sh
opencode api get /api/info
```

## Relationship to project config

This repository only supplies **global** configuration. OpenCode merges config
files from lowest to highest precedence:

1. `~/.config/opencode/opencode.jsonc` (this repo)
2. ancestor `opencode.json(c)` files, farthest first
3. `.opencode/opencode.json(c)` files, farthest first (these override everything
   above)

Keep anything team-shared or project-specific in that project's own repository,
not here. Keep machine-specific values (absolute paths, work-local tooling) out
of the global file too — `~/`-relative paths are portable, `/home/you/...` are
not.

## Day-to-day use

Commit changes you make on this machine:

```sh
cd ~/.config/opencode
git add -A
git commit -m "describe the change"
git push
```

Pick up changes made on another machine. Run this before editing if the repo
may have moved forward — a local change blocks the pull until it is committed:

```sh
git -C ~/.config/opencode pull --rebase
```

The pre-commit hook runs automatically; if it blocks a commit it prints the
offending line and path.
