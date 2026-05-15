# Security posture

This repo is **intentionally public** and clonable in pre-auth contexts (fresh
containers, CI). Secrets stay in 1Password / macOS Keychain / `gh` keyring; the
repo only contains references and the code that reads them at runtime.

## Threat model

- Public repo → anyone can read every tracked file. Old commits too.
- Goal: nothing in the repo grants access to anything by itself.
- Auth boundary: 1Password (biometric or signed-in session), macOS Keychain,
  GitHub keyring. None of these are accessible to a stranger who reads this repo.

## What's audited

### Automated (every push and PR)

- **gitleaks** — high-entropy strings, GitHub / AWS / GCP / Slack / Stripe etc.
  token patterns. Runs in `.github/workflows/ci.yml`. A finding fails the build.
- **shellcheck** — catches sloppy shell patterns. Not security-specific, but
  reduces footguns (unquoted vars, dynamic `eval`, etc.).

### Manual (initial audit, 2026-05-15)

Performed at the start of Stage 1 of the testing+bootstrap rollout.

- Repo-wide grep for: `ghp_/ghs_/gho_/github_pat_`, `sk-`, `Bearer\s+`, raw 40+
  char alphanumeric strings, RFC1918 private IPs, email addresses.
- All `op://` references inspected: paths only, no embedded credentials.
- All secret-fetching helpers (`gh auth token`, `security find-generic-password`,
  `op read`) verified to fetch at runtime, never bake values into the repo.
- `.gitignore` + `git/.gitignore_global` reviewed for common credential
  patterns.

## Findings

| Item | Verdict | Notes |
|---|---|---|
| Embedded secrets | ✅ none | Zero hits across all scans. |
| `op://` paths visible (e.g. `op://dev/vade-app.dev/password`) | ✅ acceptable | Paths are identifiers, not credentials. `op read` still requires a signed-in 1Password session. |
| Hardcoded vault item `vade-coo-mcp-2026-04` and UUID `7mbzzpzdxjddjm2ltcar6p3cfa` in `zsh/.config/zsh/functions.zsh` | ✅ acceptable | Same argument: identifier, not credential. Renaming to an alias would obscure intent without changing the security posture. |
| Private IP `172.23.72.76` (UZH SciCloud) in `ssh/.ssh/config` | ⚠ minor disclosure | RFC1918 / VPN-only address. Not externally exploitable. Documented and accepted. |
| Email `vencislav.popov@gmail.com` in `git/.gitconfig`, `R/.Rprofile` | ✅ intentional | Public on GitHub profile, ORCID `0000-0002-8073-4199`. Same address. |
| `.claude/settings.local.json` tracked | ⚠ stylistic | Contains Bash/Read allow-list, no secrets. The `.local` suffix convention says "machine-local — don't share." Probably committed inadvertently. **Recommendation:** `git rm --cached .claude/settings.local.json` after confirming. Already added to `.gitignore_global` to prevent future re-commits. |

## Acceptable disclosures

These are intentionally visible in the repo:

- The user's name, email, ORCID — public profile info.
- GitHub username (`venpopov`), repo URLs.
- 1Password vault names (`Personal`, `UZH`, `dev`, `COO`) and item names/UUIDs.
- SSH host aliases (`uzh-cluster`, `uzh-scicloud`, `venpopov.com`, `github.com`).
- UZH SciCloud private IP — VPN-only, not externally reachable.

## What's NOT in this repo

Verified by the audit:

- No API tokens, OAuth tokens, GitHub PATs, SSH keys, TLS keys, AWS keys,
  service-account JSONs, `.netrc`, `.npmrc` auth lines, or `.env` values.
- No 1Password vault contents — just paths to read them.
- No GitHub `gh` CLI token — that's in macOS keychain, fetched at shell start
  via `gh auth token`.
- No `MEM0_API_KEY` — fetched from macOS Keychain at shell start.

## Rotation procedure

If a secret is accidentally committed:

1. **Rotate the credential immediately** in 1Password / GitHub / etc. Assume
   anything pushed to a public repo is permanently exposed, regardless of
   subsequent history rewrites.
2. Optionally remove from history via `git filter-repo` or BFG (won't undo the
   exposure, but tidies the repo).
3. Update this file with the incident if material.

## For collaborators / forks

- Don't commit `.env*`, `*.pem`, `id_rsa*`, `*.key`, or any file containing
  API tokens. `.gitignore_global` covers the common cases by default.
- Don't bake secret values into shell scripts — fetch them at runtime from a
  trusted store (1Password, Keychain, gh keyring).
- gitleaks CI runs on every push/PR and blocks merge on findings. If a finding
  is a justified false positive, propose a narrow exception via `.gitleaks.toml`
  (none committed yet — added if and when needed).

## Last reviewed

2026-05-15 (initial audit, Stage 1 of the testing+bootstrap rollout).
