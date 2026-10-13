## Version Control

I use **Jujutsu (jj)** for version control instead of git. Apply the following
rules for all repositories.

### Use workspaces for non-trivial work

Any task that will touch more than ~2 files or ~10 lines of code (i.e. work
that would become a PR) **must** be done in a new jj change.

#### Workflow

1. **Checkpoint each logical step** create a new
   change _before_ starting the step:

   ```sh
   jj new -m "<what is about to be done>"
   ```

   Use short, present-tense messages, e.g.:

   - `jj new -m "scaffold auth module"`
   - `jj new -m "add login form validation"`
   - `jj new -m "wire up API endpoint"`

   Never create a change after the work is done — the description must reflect
   the work contained within that change.

2. **Keep changes small.** Each jj change stays under ~150 changed lines
   (generated files excluded). Bigger work becomes a stack of changes, shipped
   as stacked PRs via `/stack-submit`.

3. **Stop after each change** that touches core logic, and let me review it
   (`jj dft -r @`) before continuing — unless I said to run autonomously.

#### Naming convention

Use short kebab-case names that describe the task, e.g.:

- `../fix-padding-overlay`
- `../feat-search-redesign`
- `../refactor-auth-middleware`

## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

### Available skills

`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`,
`/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`,
`/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`,
`/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`,
`/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`,
`/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`,
`/unfreeze`, `/gstack-upgrade`, `/learn`
