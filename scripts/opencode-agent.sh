#!/usr/bin/env bash
# OpenCode launcher: attribute git commits made inside OpenCode (agent shell
# tools and the built-in terminal) to a GitHub App bot account. See
# "Bot identity for agent commits" in the README for how to fill this in.
#
# Install (from the repository root):
#   1. Set APP_SLUG and BOT_ID below for your GitHub App.
#   2. cp scripts/opencode-agent.sh ~/.local/bin/opencode-agent
#      chmod +x ~/.local/bin/opencode-agent
set -euo pipefail

# --- configure for your GitHub App -------------------------------------------
APP_SLUG='<app-slug>' # bot login is <app-slug>[bot]
BOT_ID='<bot-id>' # numeric user id of that bot account
# ------------------------------------------------------------------------------

if [ "$APP_SLUG" = '<app-slug>' ] || [ "$BOT_ID" = '<bot-id>' ]; then
  echo "opencode-agent: set APP_SLUG and BOT_ID in this script first (see README)." >&2
  exit 1
fi

export GIT_AUTHOR_NAME="${APP_SLUG}[bot]"
export GIT_AUTHOR_EMAIL="${BOT_ID}+${APP_SLUG}[bot]@users.noreply.github.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

exec opencode "$@"
