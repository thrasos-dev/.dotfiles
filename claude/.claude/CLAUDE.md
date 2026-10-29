# Global preferences

Personal, cross-project preferences. These apply in every project unless a project's own
`CLAUDE.md` or explicit instructions override them.

## Package manager

- Always use **pnpm** — never npm or yarn. Install with `pnpm add` (`pnpm add -D` for dev
  deps), run scripts with `pnpm <script>`, one-off binaries with `pnpm dlx`. If a repo has
  `package-lock.json` or `yarn.lock`, flag it and prefer migrating to `pnpm-lock.yaml`.

## My skills

- **frontend-design** — use it when designing UI: building pages, layouts, or
  reshaping an existing interface.
