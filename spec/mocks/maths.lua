-- ---------------------------------------------------------------------------
-- spec/mocks/maths.lua — warp.maths mock for unit tests
-- ---------------------------------------------------------------------------

return {
  clamp = function(n, lo, hi)
    return math.max(lo, math.min(hi, n))
  end,
}
