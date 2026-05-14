### Summary

Describe the bug fixed in warp.wz and the user-visible utility behavior that
changed.

### Reproduction

Provide the smallest utility call that reproduced the issue.

```lua
-- utility usage that reproduced the bug
```

### Root Cause

Explain why string, table, list, maths, path, filesystem, or platform behavior
was wrong.

### Fix

Describe the implementation change and why it fixes the problem.

### Regression Test

Describe the regression test added or updated.

### Compatibility Impact

- [ ] Non-breaking
- [ ] Potentially breaking
- [ ] Breaking

If this changes behavior intentionally, explain why the new behavior is correct.

### Checklist

- [ ] The change is scoped to warp.wz.
- [ ] Public API changes are documented, if applicable.
- [ ] Utility behavior is covered by unit or integration tests, if applicable.
- [ ] Existing utility signatures remain compatible.
- [ ] Required checks pass:
  - [ ] `busted --verbose`
  - [ ] `luacheck .`
  - [ ] `stylua --check .`
  - [ ] `selene --display-style=quiet .`

