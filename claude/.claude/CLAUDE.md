# Global preferences

Personal, cross-project preferences. These apply in every project unless a project's own
`CLAUDE.md` or explicit instructions override them.

## Package manager

- Always use **pnpm** — never npm or yarn. Install with `pnpm add` (`pnpm add -D` for dev
  deps), run scripts with `pnpm <script>`, one-off binaries with `pnpm dlx`. If a repo has
  `package-lock.json` or `yarn.lock`, flag it and prefer migrating to `pnpm-lock.yaml`.

## My skills

- **Web/UI conventions** live in a personal skill, `web-conventions` (repo
  `thrasos-dev/web-conventions`, local clone `~/repos/web-conventions`; installed via
  `npx skills add`). To change a convention: edit `SKILL.md`, bump `metadata.version`,
  commit + push, then `npx skills update web-conventions`. Commit author must be the GitHub
  noreply `100732009+thrasos-dev@users.noreply.github.com` (not the iCloud email), or the
  push is rejected.
- `npx skills` (skills.sh) installs **GitHub sources only**. For license-gated URL skills
  (e.g. React Bits Pro, `https://pro.reactbits.dev/api/r/starter/skills`):
  `REACTBITS_LICENSE_KEY=<key> node ~/.agents/install-reactbits-pro-skill.mjs` — writes real
  files to `~/.agents/skills/<name>/` and symlinks into `~/.claude/skills/`. Re-run to
  update; won't appear in `npx skills list`.
