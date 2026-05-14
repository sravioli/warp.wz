### Summary

Describe the warp.wz documentation change.

### Documentation Changed

List the README, docs, examples, contributing guide, issue templates, pull
request templates, or annotation docs changed by this pull request.

### Reader Impact

Explain who benefits from this documentation change:

- Users calling warp.wz utility modules.
- Plugin authors depending on warp.wz.
- Contributors changing utility internals.

### Examples Touched

```lua
-- utility example changed by this pull request
```

### Behavior Change

- [ ] Documentation only
- [ ] Documents an existing behavior
- [ ] Documents a new behavior

If this documents a new behavior, link to the implementation pull request or
commit.

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

