# Tools

- Use the Github MCP server to interact with Github, instead of using the github CLI (gh).
- Use the terraform MCP server to answer questions about Terraform providers, ressources and documentation.

# git usage — mandatory workflow, in this order

Before touching any file, always:

1. **Determine the base.** Run `git fetch origin <default-branch>` and base the work on it (or on the local
   default branch only if it resolves to the same commit as `origin/main`), unless told otherwise.
2. **Create a dedicated branch in a worktree under the git root**:
   `git worktree add --no-track <git-root>/worktrees/<branch-name> -b <branch-name> <base>`.
   Branch names are short and descriptive (`feature/...`, `fix/...`, `issue/<n>-...`).
3. **Move the session into the worktree** (e.g. `tools.opencode.session_move`), then do *all* work there: analysis,
   edits, verification (`pre-commit`, `terraform test`, `pytest`), commits and pushes.

Rules:

- Never edit files in the primary checkout. Leave the user's working tree exactly as found — staged, unstaged and
  untracked changes there belong to the user, do not touch or revert them.
- Use git rebase over git merge to resolve merge conflicts whenever feasible.
- Within an existing worktree, new branches still follow `"git checkout -b <new_branch> <base_branch> --no-track"`.
- Periodically clean up worktrees whose branch is gone: `git worktree remove <git-root>/worktrees/<branch-name>` and
  delete the branch (`git branch -d ...`) if it is merged.
