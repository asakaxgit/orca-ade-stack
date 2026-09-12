# Handoff for agents inside Orca ADE

## Shell
`~/.bashrc` (before interactive early-return): nodenv, rbenv, direnv, `~/.local/bin`.

## Project env
`cd` into the workspace → direnv loads `.envrc` then `.local.envrc` (secrets, mode 600).

## Verify
```bash
node -v; ruby -v
test -n "$GITHUB_TOKEN" && test -n "$GOOGLE_APPLICATION_CREDENTIALS" && echo env_ok
```

Do not paste or log secret values. Do not put secrets in `~/.bashrc`.
