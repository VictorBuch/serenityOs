---
name: stack-submit
description: Push a linear stack of jj changes as stacked GitHub PRs (each PR based on the one below it), and keep the stack in sync after edits or merges. Use when the user says "/stack-submit", "submit the stack", "push the stack", or "update the stack".
argument-hint: "[CMS-XXX] | sync"
---

# Stack submit

A stack is the linear chain `trunk()..@` of non-empty, described jj changes. Each change becomes one bookmark and one PR whose base is the previous change's bookmark (`develop` for the bottom one).

## Submit

1. List the stack bottom→top: `jj log -r 'trunk()..@ & ~empty()' --reversed --no-graph -T 'change_id.shortest() ++ " " ++ description.first_line() ++ " " ++ bookmarks ++ "\n"'`. Stop if there's a merge, an undescribed change, or a conflict, and tell the user.
2. Bookmark names: `<ticket-lowercase>-<n>-<kebab-slug>` (e.g. `cms-412-1-add-schema`), or `<n>-<slug>` without a ticket. Reuse a change's existing bookmark if it has one.
3. **Show the plan** (bookmark → base → title for each) and confirm once. Pushing is outward-facing.
4. For each change bottom→top: `jj bookmark set <name> -r <change>`, then `jj git push -b <name>` (add `--allow-new` if jj asks).
5. Create each PR bottom→top: `gh pr create --base <prev bookmark or develop> --head <name> --title "<description>" --body-file <tmp>`. The body is:

   ```markdown
   <what this change does and why; 1–3 lines>

   Part of CMS-XXX            ← use "Closes CMS-XXX" on the TOP PR only
   ## Stack
   - #<n1> <title>
   - **→ #<n2> <title>** (this PR)
   - #<n3> <title>

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   ```

   Create all the PRs first, then `gh pr edit --body-file` each one so the stack list has every PR number. Use `[no-ticket]` instead of `Part of`/`Closes` for chores.
6. Print the PR URLs bottom→top. Reviewers should review bottom-up.

## Sync

Use this after editing a change in the stack (jj rebases descendants automatically) or after a PR merges.

1. `jj git fetch`
2. If the bottom PR merged: `jj rebase -s <next change> -d develop`, then `gh pr edit <next PR> --base develop`. (GitHub auto-retargets when the merged branch is deleted, but set it explicitly anyway.) Abandon the merged change if it's still there and empty.
3. Push every bookmark in the stack: `jj git push -b <name>` for each.
4. Refresh the stack lists in the PR bodies if PRs were added or removed.
