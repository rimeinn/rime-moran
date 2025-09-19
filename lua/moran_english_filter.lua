-- moran_english_filter.lua
--
-- Version: 0.1.1
-- Author:  ksqsf
-- License: GPLv3
--
-- 0.1.1: Relax matching criteria.
-- 0.1: Add.

-- == Developer notes ==
--
-- A word is said to be 'proper' if it contains at least one uppercase
-- letter. The naming is from 'proper noun'.
--
-- We assume that the way the English translator finds candidates is fuzzy:
--  1. Non-proper input can match any word.
--  2. ([a-zA-Z][a-z]*) can match non-proper word.
--
-- For example:
--  1. "hello" can find "hello", "hELLO", "Hello".
--  2. "Hello" can find "Hello", "hello", but not "HEllo".
--
-- The goal of this filter is to match the case of proper input with
-- proper candidates.
--
-- The expected use case is:
--  1. moran_english.dict.yaml contains a list of non-proper words, e.g. "hello"
--  2. Proper input "Hello" finds "hello"
--  3. This filter modifies the output so that the candidate becomes "Hello".

local moran = require("moran")

local Module = {}

-----------------------------------------------------------------------

local PAT_UPPERCASE = "[A-Z]"
local PAT_ENGLISH_WORD = "^[a-zA-Z0-9 &!@#$%^&*()-=_+[%]\\\\{}'\";,./<>?]+$"

-- | Check if @s is proper: contains at least one capital letter.
--
-- @param s str
-- @return true if proper; false otherwise
local function str_is_proper(s)
   return s:find(PAT_UPPERCASE) ~= nil
end

-- | Check if @s is an English word.
--
-- @param s str
-- @return true if it can be considered an English word
local function str_is_english_word(s)
   return s:find(PAT_ENGLISH_WORD) ~= nil
end

-- | Check if the common prefix of @a and @b are equal (case-sensitive).
local function match_case(a, b)
   -- local len = math.min(#a, #b)
   -- return a:sub(1, len) == b:sub(1, len)

   -- Should be more relaxed, because we only fuzzy match on the first letter.
   return a:sub(1,1) == b:sub(1,1)
end

-- | Fix the case of @str to match that of @std.
local function fix_case(str, std)
   -- if #std >= #str then
   --    return std:sub(1, #str)
   -- else
   --    local len = math.min(#str, #std)
   --    return std:sub(1, len) .. str:sub(len + 1, -1)
   -- end

   -- Should be more relaxed, because we only fuzzy match on the first letter.
   if not str or not std then
      return ""
   end
   return std:sub(1,1) .. str:sub(2, -1)
end

-- | A fast check on the first byte of the string.
local function not_filterable(s)
   return #s > 0 and s:byte(1) >= 128
end

-----------------------------------------------------------------------

function Module.init(env)
end

function Module.fini(env)
end

function Module.func(t_input, env)
   local composition = env.engine.context.composition
   if composition:empty() then
      return
   end

   local segmentation = composition:toSegmentation()
   local seg = segmentation:back()
   local iter = moran.iter_translation(t_input)
   if not seg:has_tag("english") then
      moran.yield_all(iter)
      return
   end

   -- If input is non-proper, do nothing.
   local input = segmentation.input:sub(seg._start + 1, seg._end + 1)
   if not str_is_proper(input) then
      moran.yield_all(iter)
      return
   end

   -- Proper (non-trivial) input means we need to fix non-proper candidates.
   for c in iter do
      if not_filterable(c.text) or not str_is_english_word(c.text) then
         yield(c)
      elseif not str_is_proper(c.text) then
         -- c is fixable.
         local fixed_text = fix_case(c.text, input)
         yield(ShadowCandidate(c, "english", fixed_text, "", true))
      else
         -- c is proper. It cannot be changed.
         if match_case(c.text, input) then
            yield(c)
         end
      end
   end
end

return Module
