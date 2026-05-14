### Summary

Describe the new warp.wz feature and the user-facing utility workflow it
enables.

### Motivation

Explain why this belongs in warp.wz. Focus on reusable string, table, list,
maths, path, or filesystem helpers for WezTerm plugins.

### API Sketch

```lua
-- show intended utility module usage
```

### Behavior

Describe how the feature behaves, including input shape, return values,
edge-case handling, platform-specific behavior, and failure cases.

### Compatibility

- [ ] Non-breaking
- [ ] Potentially breaking
- [ ] Breaking

If this is potentially breaking or breaking, explain the migration path.

### Tests

Describe the unit or integration tests added or updated for this behavior.

### Documentation

Describe the README, docs, examples, annotation, or template changes made for
this feature.

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

