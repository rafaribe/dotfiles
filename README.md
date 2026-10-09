# dotfiles

Personal dotfiles, managed with [chezmoi](https://chezmoi.io).

```fish
chezmoi init --apply rafaribe
```

- **Secrets** are age-encrypted. Put the age identity at `~/.config/chezmoi/key.txt`
  before applying. Machines without it skip the encrypted files.
- **tmux** uses [tpm](https://github.com/tmux-plugins/tpm), which chezmoi clones
  (`.chezmoiexternal.toml`). Plugins install on first tmux launch.
- **Layering:** other dotfiles sources can add files to these drop-in points
  without this repo knowing about them: `~/.config/fish/conf.d/`, `~/.ssh/config.d/`,
  and `~/.config/git/config.extra`.
- **Leak guard:** `.leak-guard/` blocks commits and pushes that contain forbidden
  terms (stored as hashes). chezmoi turns on the hooks; CI checks again on every push.
  Add a term with `.leak-guard/leak_guard.py hash TERM` and paste the result into `TERMS`.
