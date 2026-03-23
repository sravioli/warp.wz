---@module 'warp.maths'

local min, max = math.min, math.max

---@class Warp.Maths
local M = {}

local magic = 2 ^ 52 + 2 ^ 51

---Round number to nearest integer.
---
---@param number number Number to round.
---@return integer result Closest integer number.
M.round = function(number)
  return number + magic - magic
end

---Round number to nearest given multiple.
---
---@param number   number  Number to round.
---@param multiple integer Target multiple.
---@return integer result Number rounded to closest multiple.
M.round_to = function(number, multiple)
  return ((number / multiple + magic) - magic) * multiple
end

---Returns a number between `minimum` and `maximum`, inclusive.
---
---@param number number
---@param minimum number
---@param maximum number
---@return number
M.clamp = function(number, minimum, maximum)
  return max(minimum, min(maximum, number))
end

return M
