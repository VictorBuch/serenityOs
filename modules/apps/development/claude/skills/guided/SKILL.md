---
name: guided
description: Learning-first ticket workflow. Map the code, the user predicts the plan, build as a gated stack of small jj changes with a review tour and quiz after each, ship stacked PRs, log what was learned. Use when the user says "/guided" or "guided mode".
argument-hint: "<CMS-XXX or task> | review"
disable-model-invocation: true
---

# Guided

The user wants to ship at a good pace while staying engaged, understanding every change, and learning. They have accepted a 30–40% speed cost for this. Your job is to keep the **judgment and the reading** with them and take the typing. Never hand them a summary in place of the code. Point them at the code instead.

If the argument is `review`, skip to [Weekly review](#weekly-review).

## 1. Map (no solutions yet)

If given a `CMS-XXX`, fetch the issue from Linear. Then explore the code the ticket touches and give the user a **guided tour**:

- the entry point and the data flow, as an ordered list of `file:line` stops
- one line per stop on *why it matters for this ticket*
- the 1–2 project concepts they need to understand (e.g. per-request `React.cache` vs SWR, tenant resolution), each with a pointer to where it lives

Keep it under ~25 lines. Don't propose an approach. End with: *"Your turn: how would you do it? Which files, what approach, what's the risky part?"*, then **stop and wait**.

## 2. Predict, then plan

The user writes their plan. Respond with:

1. **Critique**: what they got right, what they missed, what you'd do differently and why. Be direct; this is the main learning moment.
2. **The stack**: an ordered list of jj changes, each ≤ ~150 changed lines (generated files like locales, migrations, lockfiles and snapshots don't count). Each change must be independently reviewable, and later changes build on earlier ones. Tag each one:
   - `claude`: boilerplate, wiring, tests scaffolding, translations, renames
   - `you`: core logic, data-flow or caching decisions, anything tricky. The user writes the heart of it (see step 3).

   Aim for at least one `you` change per ticket.

Wait for approval or edits to the stack.

## 3. Build, gated

For each change in the stack, in order:

1. `jj new -m "<change description>"`
2. **`claude` change:** implement it. **`you` change:** write the scaffolding (types, call sites, test cases), then leave a `// TODO(human): …` at the core with a precise spec: inputs, expected output, edge cases to handle. Tell the user where it is and wait. When they say done, review their code like a senior reviewer: correctness first, then idiom. Fix nothing yourself unless they ask. If they ask for help, give a hint first, not the answer.
3. Run the relevant checks (tests, `pnpm run ts-check` / lint where cheap).
4. **Review tour.** Show `jj diff --stat -r @`, tell them to run `jj dft -r @`, and give an ordered reading list (`file:line`, one line each on *what to look at*, e.g. "the empty-destination branch", not "adds a function").
5. **Quiz.** Ask 2 questions they can only answer if they read the diff: behaviour on an edge case, why this approach over an alternative, what breaks if a line is removed. No trivia. Wait for their answers, grade them honestly, and explain any misses. Remember the misses for step 5.
6. **Stop.** Continue only on "next" (or similar).

If a change grows past ~150 lines while building, stop and split it.

### Speed controls

- `skip quiz`: skip step 3.5 for this change.
- `fast`: for routine tickets. Shorten the map to 5 lines, keep the gates and review tours, drop the quizzes.
- `just do the rest`: build the remaining `claude` changes without stopping, each still its own jj change. Then give one combined review tour and a 3-question quiz over all of them. `you` changes are never skipped unless the user explicitly says so.

## 4. Ship

Invoke the `stack-submit` skill. Then run `cms-code-review` on the **top PR only**; its diff against `develop` covers the whole stack.

## 5. Log

Append to `~/notes/learning-log.md` (create it if missing):

```markdown
## YYYY-MM-DD: CMS-XXX <short title>
- Learned: <1–3 concrete, non-obvious things about this codebase or technique>
- Plan delta: <what their plan missed vs. what shipped>
- Missed: <question> → <answer>
```

Only log `Missed:` lines for questions they actually got wrong. Show the entry and let them edit it.

## Weekly review

Read the last 4 weeks of `~/notes/learning-log.md`. Re-ask up to 5 `Missed:` questions that don't have a ✓, one at a time, rephrased so they can't pattern-match. Append ` ✓ YYYY-MM-DD` to each one they now get right. Finish with 2–3 lines on the patterns you see (e.g. "plan deltas keep missing caching implications").
