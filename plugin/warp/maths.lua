---@module "warp.maths"

local min, max = math.min, math.max

---@class Warp.Maths
local M = {}

---IEEE 754 double-precision rounding constant (`2^52 + 2^51`).
---
---Adding then subtracting this value forces the FPU to snap a float to the nearest
---integer using round-half-to-even.
---@type number
local magic = 2 ^ 52 + 2 ^ 51

---Round a number to the nearest integer (half-to-even).
---
---Uses an IEEE 754 double-precision trick: adding then subtracting a magic constant
---forces the floating-point unit to round to the nearest representable integer. Ties
---are broken by rounding to the nearest even integer (banker's rounding), e.g.
---`0.5` → `0`, `1.5` → `2`, `2.5` → `2`.
---
---Only accurate for numbers whose absolute value is less than
---`2^51` (`2251799813685248`).
---
---@param number number Number to round.
---@return integer result Nearest integer (half-to-even).
M.round = function(number)
  return number + magic - magic
end

---Round a number to the nearest given multiple (half-to-even).
---
---Divides by `multiple`, rounds the quotient using the same IEEE 754 half-to-even
---trick as [round](lua://Warp.Maths.round), then multiplies back.
---
---@param number   number  Number to round.
---@param multiple integer Target multiple (must be non-zero).
---@return integer result Nearest multiple of `multiple`.
M.round_to = function(number, multiple)
  return ((number / multiple + magic) - magic) * multiple
end

---Clamp a number to the range [`minimum`, `maximum`].
---
---Returns `minimum` when `number` is below the range, `maximum` when above, or
---`number` itself when already within bounds.
---
---@param number  number Value to clamp.
---@param minimum number Lower bound (inclusive).
---@param maximum number Upper bound (inclusive).
---@return number result Clamped value.
M.clamp = function(number, minimum, maximum)
  return max(minimum, min(maximum, number))
end

return M
