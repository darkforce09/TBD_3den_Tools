# Worktrees

Every linked git worktree of this checkout lives here, one folder per worktree
(`git worktree add .worktrees/<name>`). Everything in this folder except this
README is gitignored. Never stage a worktree folder: git would record it as an
embedded repository.
