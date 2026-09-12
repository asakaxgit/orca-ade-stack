# Orca ADE VPS stack (reusable)

Reusable definition to create the **next** Ubuntu VPS for headless [Orca ADE](https://www.onorca.dev), matching the hardened `orca` Linode pattern — **without secrets**.

## Target shape
- Ubuntu 24.04+ / 26.04 LTS, **≥ 8 GiB RAM** (4 GiB OOMs with agents + builds)
- User `orca` (nologin OK; Orca terminals still source `~/.bashrc`)
- Tailscale-only admin SSH + orca-serve on `:6768` (UFW denies public `eth0` for 22/6768)
- fail2ban + CrowdSec, unattended-upgrades
- nodenv (Node 22.18.0) + rbenv (Ruby 3.3.4) + direnv
- Optional: Claude Code CLI, Cursor agent CLI, `gh`, `gcloud` (logins are **post-boot manual**)

## Files
| Path | Purpose |
|------|---------|
| `cloud-init.yaml` | Linode / cloud-init **user-data** (packages, users, base harden, first boot) |
| `linode-create.example.sh` | Example `linode-cli` / API create with this user-data |
| `scripts/01-tailscale-and-lockdown.sh` | Join Tailscale, then bind SSH + UFW to Tailscale |
| `scripts/02-orca-serve.sh` | Install AppImage + systemd `orca-serve` |
| `scripts/03-dev-toolchains.sh` | nodenv/rbenv/direnv + optional agent CLIs |
| `templates/orca-serve.service` | systemd unit (pairing address filled at install) |
| `templates/sshd-hardening.conf` | SSH keys-only drop-in |
| `templates/ssh.socket.override.conf` | Listen Tailscale + localhost only |
| `templates/fail2ban-sshd.local` | fail2ban jails |
| `templates/local.envrc.example` | Project secrets **placeholders only** |
| `templates/agent-env-handoff.md` | Text for agents inside Orca ADE |

## Secrets (never in git / never in this repo)
Provide at create-time or after boot via secure channel — not chat:
1. Tailscale **auth key** (reusable/ephemeral as you prefer)
2. SSH **public** keys for root (and optionally `orca`)
3. Orca AppImage URL or local copy (version pin)
4. After boot: `gh` / Claude / Cursor / gcloud ADC / `GITHUB_TOKEN` in project `.local.envrc`

## Suggested create order
1. Create VPS with `cloud-init.yaml` (inject SSH pubkeys — see comments in file). Prefer plan **≥ 8 GiB**.
2. First boot installs packages + base SSH harden (password auth off), keeps public SSH until Tailscale is up, and **`git clone`s this public repo to `/root/orca-ade-stack`** (scripts included automatically).
3. SSH in → `TAILSCALE_AUTH_KEY=… /root/orca-ade-stack/scripts/01-tailscale-and-lockdown.sh`
4. `/root/orca-ade-stack/scripts/02-orca-serve.sh` then `03-dev-toolchains.sh`
5. Pair Orca client over Tailscale; do interactive logins in an Orca terminal.
6. Hand day-to-day ops to an ops bot; this repo stays the **build** recipe.

Repo: https://github.com/asakaxgit/orca-ade-stack

## Linode notes
- Plan: `g6-standard-4` (8 GiB) minimum for this workload.
- Region/image: match your preference (`linode/ubuntu24.04` or `ubuntu26.04`).
- Attach a cloud firewall if desired; still keep host UFW as defense in depth.
