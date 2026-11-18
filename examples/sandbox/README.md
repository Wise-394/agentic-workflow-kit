# Sandbox

A tiny project for testing the kit end to end. Copy it into a new, empty repository you own (never test in a real project):

```bash
cp -r examples/sandbox <temp>/kit-sandbox && cd <temp>/kit-sandbox
git init -b main && git add . && git commit -m "chore: sandbox"
gh repo create kit-sandbox --private --source . --push
git switch -c dev && git push -u origin dev
```

Then follow [docs/release-checklist.md](../../docs/release-checklist.md).

- Check command: `npm run check`
- Test one file: `npm test -- <file>`
- No packages to install. Tests use Node's built-in runner.

## Issues to file for the release run

1. **Feature:** "Add `average(numbers)` that returns the mean, and 0 for an empty list." Label `type:feature`.
2. **Bug:** "`sum` returns a string when given numeric strings such as `['1', '2']`; it should return 3." Label `type:bug`.
3. **Sprint:** put two small features in a milestone (for example `max(numbers)` and `min(numbers)`, with `min` blocked by `max`) plus a `type:verify` issue.
