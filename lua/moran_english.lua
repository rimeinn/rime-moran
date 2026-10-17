-- moran_english.lua
--
-- Version: 0.3.7
-- Author:  ksqsf
-- License: GPLv3
--
-- 0.3.7: Capitalizer now upcase the entire word if input is all caps,
--        and only fix the initial letter.
-- 0.3.6: Restrict auto trigger.
-- 0.3.5: Disable indicator for auto trigger.
-- 0.3.4: Allow adding words with spaces.
-- 0.3.3: Fix some corner cases.
-- 0.3.2: Use segment code instead of all code for word creation.
-- 0.3.1: Fix compatibility issue with rime-mkm.
-- 0.3.0: Added Translator to search user words using non-proper spelling.
-- 0.2.0: Added WordCreator.  Renamed from moran_english_filter.lua.
-- 0.1.1: Relax matching criteria.
-- 0.1: Add.
--
-- This module contains the following components:
--
-- * Translator: query the original input and its lowercase spelling.
--
-- * Capitalizer: automatically fix the case of the output candidates
--   to match the input.  For example, if you type "Monkey", and the
--   dictionary lookup returns "monkey", this filter will update
--   "monkey" to be "Monkey".
--
-- * WordCreator: echo the segment code, but if you commit it, it will
--   be stored into the English translator's user dict.

local moran = require("moran")

local Module = {}

-----------------------------------------------------------------------

local PAT_UPPERCASE = "[A-Z]"
local PAT_ENGLISH_WORD = "^[a-zA-Z0-9 &!@#$%^&*()-=_+[%]\\\\{}'\";,./<>?]+$"
local PAT_NEW_WORD_PREFIX = "^[a-zA-Z][a-zA-Z/]*[^/]"  -- Reject trailing spaces and slashes
local PAT_NEW_WORD_WHOLE = PAT_NEW_WORD_PREFIX .. "$"

-- | Check if @s is proper: contains at least one capital letter.
--
-- @param s str
-- @return true if proper; false otherwise
local function is_proper(s)
    return s:find(PAT_UPPERCASE) ~= nil
end

-- | Check if @s is an English word.
--
-- @param s str
-- @return true if it can be considered an English word
local function is_english_word(s)
    return s:match(PAT_ENGLISH_WORD)
end

-- | Check if the common prefix of @a and @b are equal
-- | (case-sensitive), but ignoring spaces in @a.
local function match_case_ignoring_spaces(a, b)
    if a:find(" ") then
        a = a:gsub(" ", "")
    end
    if #a > #b then
        a, b = b, a
    end
    return a == b:sub(1, #a)
end

-- | A fast check on the first byte of the string.
--
-- PRE: #s >= 1
local function not_filterable(s)
    return s:byte(1) >= 128
end

-----------------------------------------------------------------------
-- Translator
-----------------------------------------------------------------------
local Translator = {}

function Translator.init(env)
    env.translator = Component.Translator(env.engine, "", "table_translator@english")
end

function Translator.fini(env)
    env.translator = nil
    collectgarbage()
end

function Translator.func(input, seg, env)
    local original = moran.make_peekable(moran.query_translation(env.translator, input, seg))
    local lower = input:lower()
    if lower == input then
        moran.yield_all(original)
        return
    end
    -- Case fold by querying lowercase.
    local folded = moran.make_peekable(moran.query_translation(env.translator, lower, seg, function(c)
        c.preedit = input
        return c
    end))
    while original:peek() and folded:peek() do
        if original:peek().quality >= folded:peek().quality then
            yield(original())
        else
            yield(folded())
        end
    end
    moran.yield_all(original)
    moran.yield_all(folded)
end

-----------------------------------------------------------------------
-- Capitalizer
-----------------------------------------------------------------------
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

local Capitalizer = {}

function Capitalizer.init(env)
end

function Capitalizer.fini(env)
end

function Capitalizer.func(t_input, env)
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
    local input = segmentation.input:sub(seg._start + 1, seg._end)
    if #input == 0 or input:match("^[a-z]+$") then
        moran.yield_all(iter)
        return
    end

    local input_all_caps = input:match("^[A-Z]+$")
    local input_only_first_cap = not input_all_caps and input:match("^[A-Z][a-z]*$")

    -- If input is proper, i.e. contains at least one uppercase letter.
    --
    -- * when I is fuzzy (same case; and I must be all caps due to
    --   being proper): the candidate should be fixed to be all caps.
    --
    -- * when I is exact, i.e., not fuzzy: match the case exactly, but
    --   only fix the first letter.
    local input = segmentation.input:sub(seg._start + 1, seg._end)
    for c in iter do
        if #c.text == 0 then
            yield(c)
        elseif not_filterable(c.text) or not is_english_word(c.text) then
            yield(c)
        elseif is_proper(c.text) then
            if match_case_ignoring_spaces(c.text, input) then
                yield(c)
            end
        elseif input_all_caps then
            local fixed_text = c.text:upper()
            yield(ShadowCandidate(c, "english", fixed_text, "", true))
        elseif input_only_first_cap then
            local fixed_text = input:sub(1,1) .. c.text:sub(2,-1)
            yield(ShadowCandidate(c, "english", fixed_text, "", true))
        end
    end
end

-----------------------------------------------------------------------
-- Word Creator
-----------------------------------------------------------------------
local WordCreator = {}

function WordCreator.init(env)
    -- 'english_add_word' must not enable user dict!  The trick here
    -- is that table_translator@english also listens for commits and
    -- hence user dict updates.  The point of this memory is just to
    -- pass 'language' to that Memory.
    --
    -- If we do not disable user dict here, there will be TWO Memory
    -- objects listening for deletion.
    env.memory = Memory(env.engine, env.engine.schema, "english_add_word")
    env.enabled = moran.get_config_bool(env, "moran/english/add_word/enable", true)
    env.indicator = env.engine.schema.config:get_string("moran/english/add_word/indicator") or "*"
    env.trigger = env.engine.schema.config:get_string("moran/english/add_word/trigger") or "/add?"
end

function WordCreator.fini(env)
    env.memory:disconnect()
end

function WordCreator.func(t_input, env)
    local iter = moran.iter_translation(t_input)
    if not env.enabled then
        moran.yield_all(iter)
        return
    end
    local context = env.engine.context
    local composition = context.composition
    if composition:empty() then
        return
    end
    local seg = composition:back()
    local input = context.input:sub(seg.start + 1, seg._end)
    if not seg:has_tag("abc") then
        moran.yield_all(iter)
        return
    end
    local iter = moran.make_peekable(iter)
    local peek = iter:peek()
    -- Notable corner cases:
    -- 1. non-ascii code (e.g. in kagiroi and mungyeong)
    -- 2. punct_number auto commit
    -- 3. empty candidates from ("" + trigger)
    -- and more.  See moran.test.yaml.
    local auto_trigger = not peek and input:match(PAT_NEW_WORD_WHOLE)  -- reject input with non-alpha chars
        and not moran.segment_is_reverse_lookup(seg)
    if auto_trigger
        or input:match(PAT_NEW_WORD_PREFIX .. env.trigger .. "$")      -- manual trigger
    then
        local word = input:gsub(env.trigger .. "$", "", 1):gsub("/", " ")
        local entry = DictEntry()
        entry.text = word
        entry.preedit = word
        entry.custom_code = word:gsub(" ", ""):lower() .. " "
        entry.weight = -1e10         -- slightly below 0
        local phrase = Phrase(env.memory, "english", seg.start, seg._end, entry)
        if not auto_trigger then
            phrase.comment = env.indicator
        end
        yield(phrase:toCandidate())
    end
    moran.yield_all(iter)
end

return {
    translator = Translator,
    capitalizer_filter = Capitalizer,
    add_word_filter = WordCreator,
}

-- Local Variables:
-- lua-indent-level: 4
-- End:
