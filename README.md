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
- **`~/.local/bin/opencode-agent`** — the bot-identity launcher for OpenCode.
  Machine-local, outside the repo, documented in
  [Bot identity for agent commits](#bot-identity-for-agent-commits-github-app)
  below.

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

## Bot identity for agent commits (GitHub App)

The rule on this machine: **git inside OpenCode is the GitHub App bot, git
outside is me.** Commits made through agent shell commands and OpenCode's
built-in terminal are attributed to the bot account of a GitHub App;
commits made in ordinary terminals keep my personal identity. Comments,
reviews and issues made through the GitHub MCP server carry the same bot
identity automatically — there it comes from the app's installation token
configured in `opencode.jsonc`. Git *commits* are different: git takes its
identity from `GIT_AUTHOR_*`/`GIT_COMMITTER_*` environment variables, so
whatever launches OpenCode has to set them.

### Deriving the bot's name and email

Git needs two values:

| git variable | value |
| --- | --- |
| `GIT_AUTHOR_NAME`, `GIT_COMMITTER_NAME` | `<app-slug>[bot]` |
| `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_EMAIL` | `<bot-id>+<app-slug>[bot]@users.noreply.github.com` |

Both derive from the GitHub App (Settings → Developer settings → GitHub
Apps → the app):

1. **Name/login** — the bot account is the app's slug with `[bot]`
   appended, e.g. app slug `my-toolbox` → `my-toolbox[bot]`. The same
   settings page shows the **App ID**; the **Installation ID** is the
   number in the Install App URL, `github.com/settings/installations/<ID>`
   (both are needed to authenticate the GitHub MCP server with the app).
2. **Numeric user id** — the bot account's id, public through the users
   API (encode `[`/`]` as `%5B`/`%5D`):

   ```sh
   curl -s 'https://api.github.com/users/<app-slug>%5Bbot%5D' | jq -r .id
   ```

   Alternatively read `user.id` from anything the bot has already
   produced, e.g. the author of a comment it posted.
3. **Email** — GitHub's noreply format `<id>+<login>@users.noreply.github.com`,
   assembled from steps 1 and 2.

GitHub links a commit to the bot account only when the email matches this
address exactly; any other address renders as literal text with no avatar.
The numeric id is stable, but **renaming the app changes the login** — after
a rename, redo steps 1 and 3 and update the wrapper and the alias below.

### Launcher: wrapper script

`~/.local/bin/opencode-agent` (`~/.local/bin` is on PATH). Replace the
placeholders with the values derived above:

```sh
#!/usr/bin/env bash
export GIT_AUTHOR_NAME='<app-slug>[bot]'
export GIT_AUTHOR_EMAIL='<bot-id>+<app-slug>[bot]@users.noreply.github.com'
export GIT_COMMITTER_NAME='<app-slug>[bot]'
export GIT_COMMITTER_EMAIL='<bot-id>+<app-slug>[bot]@users.noreply.github.com'
exec opencode "$@"
```

```sh
chmod +x ~/.local/bin/opencode-agent
opencode-agent      # instead of: opencode
```

### Launcher: alias (optional)

Bash refuses to expand an alias whose replacement starts with itself, so
wrapping the command name sets the variables only for the OpenCode process —
`git commit` typed next to it is untouched:

```sh
# ~/.bashrc
alias opencode='GIT_AUTHOR_NAME="<app-slug>[bot]" GIT_AUTHOR_EMAIL="<bot-id>+<app-slug>[bot]@users.noreply.github.com" GIT_COMMITTER_NAME="<app-slug>[bot]" GIT_COMMITTER_EMAIL="<bot-id>+<app-slug>[bot]@users.noreply.github.com" opencode'
```

Interactive shells get the alias; non-interactive launches (scripts, launch
configs, cron) do not — use `opencode-agent` for those. Plain `opencode`
started without either launcher falls back to my personal identity, which
is the intended safety default.

### Why the launcher, not the service environment

OpenCode gives shell tools the **client's** environment: spawned shells
match the TUI process in `/proc/<pid>/environ`, not the background service
process. Exporting `GIT_*` for whatever supervises the background service
(e.g. a `systemd --user` unit) therefore has no effect on shell tools. The
variables must be set on whatever *launches OpenCode* — that is the one
path that changes git's identity.

### Verify

From inside a session:

```sh
env | grep ^GIT_
d=$(mktemp -d) && cd "$d" && git init -q . && echo x > f && git add f \
  && git commit -qm check \
  && git log -1 --format='%an <%ae> | %cn <%ce>' \
  && cd / && rm -rf "$d"
```

The commit line should read
`<app-slug>[bot] <bot-id>+<app-slug>[bot]@users.noreply.github.com>`.

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
