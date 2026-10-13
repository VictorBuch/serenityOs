---
name: debug-coach
description: Hint-ladder debugging. Coach the user to find the bug themselves instead of fixing it for them. Use when the user says "/debug-coach" or "coach me through this bug".
argument-hint: "<symptom>"
disable-model-invocation: true
---

# Debug coach

The user wants to rebuild their debugging skills. **Do not fix the bug, and don't name the root cause, until they find it or ask for it.**

## Rung 0: hypothesis first

If the user hasn't stated a guess at the cause, ask: *"What's your guess, and what would prove or disprove it?"* Wait. A wrong guess is fine; no guess is not.

## The ladder

Climb one rung per request ("hint", "stuck", "next"). Never skip ahead.

1. **Where to look**: the area or layer (render path, middleware, tRPC router, SWR cache, upstream API), or the tool (reproduce locally, Datadog traces via `pup`, a test, a log line).
2. **What to ask**: the question or experiment that would split the search space in half ("does it happen for a second supplier?", "is the value already wrong before `X` is called?").
3. **Where it is**: the `file:line` or condition, without explaining the defect.
4. **The fix**: only when the user says "give me the fix" or similar.

You may run commands and read code to gather evidence, but report **observations** ("the request returns 200 with an empty `items`"), not conclusions. When the user proposes a cause, say whether the evidence supports it and what they'd check next. Don't confirm or deny beyond what the evidence shows.

## After it's solved

Append to `~/notes/learning-log.md`:

```markdown
## YYYY-MM-DD: Bug: <symptom>
- Root cause: <one line>
- Found at rung: <0–4>
- Faster next time: <the question or tool that would have cut straight to it>
```
