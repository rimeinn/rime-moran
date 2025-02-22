-- moran_processor.lua
-- Synopsis: 適用於魔然方案默認模式的按鍵處理器
-- Author: ksqsf
-- License: MIT license
-- Version: 0.2

-- 主要功能：
-- 1. 選擇第二個首選項，但可用於跳過 emoji 濾鏡產生的候選
-- 2. 快速切換強制切分

-- ChangeLog:
--  0.2.0: 增加快速切換切分的能力，因而從 moran_semicolon_processor 更名爲 moran_processor
--  0.1.5: 修復獲取 candidate_count 的邏輯
--  0.1.4: 數字也增加到條件裏

local moran = require("moran")

local kReject = 0
local kAccepted = 1
local kNoop = 2

local function semicolon_processor(key_event, env)
   local context = env.engine.context

   if key_event.keycode ~= 0x3B then
      return kNoop
   end

   local composition = context.composition
   if composition:empty() then
      return kNoop
   end

   local segment = composition:back()
   local menu = segment.menu
   local page_size = env.engine.schema.page_size

   -- Special cases: for 'ovy' and 快符, just send ';'
   if context.input:find('^ovy') or context.input:find('^;') then
      return kNoop
   end

   -- Special case: if there is only one candidate, just select it!
   local candidate_count = menu:prepare(page_size)
   if candidate_count == 1 then
      context:select(0)
      return kAccepted
   end

   -- If it is not the first page, simply send 2.
   local selected_index = segment.selected_index
   if selected_index >= page_size then
      local page_num = selected_index // page_size
      context:select(page_num * page_size + 1)
      return kAccepted
   end

   -- First page: do something more sophisticated.
   local i = 1
   while i < page_size do
      local cand = menu:get_candidate_at(i)
      if cand == nil then
         context:select(1)
         return kNoop
      end
      local cand_text = cand.text
      local codepoint = utf8.codepoint(cand_text, 1)
      if moran.unicode_code_point_is_chinese(codepoint) -- 漢字
         or (codepoint >= 97 and codepoint <= 122)      -- a-z
         or (codepoint >= 65 and codepoint <= 90)       -- A-Z
         or (codepoint >= 48 and codepoint <= 57 and cand.type ~= "simplified") -- 0-9
      then
         context:select(i)
         return kAccepted
      end
      i = i + 1
   end

   -- No good candidates found. Just select the second candidate.
   context:select(1)
   return kAccepted
end

local function force_segmentation_processor(key_event, env)
   if not (key_event:ctrl() and key_event.keycode == 0x6c) then  -- ctrl+l
      return kNoop
   end

   local composition = env.engine.context.composition
   if composition:empty() then
      return kNoop
   end

   local seg = composition:back()
   local cand = seg:get_selected_candidate()
   if cand == nil then
      return kNoop
   end

   local ctx = env.engine.context
   local input = ctx.input:sub(seg._start + 1, seg._end)
   local preedit = cand.preedit

   local raw = input:gsub("'", "")  -- 不帶 ' 分隔符的輸入

   if preedit:match("^[a-z][a-z][ '][a-z][a-z][a-z]$") or input:match("^[a-z][a-z]'[a-z][a-z][a-z]$") then  -- 2-3
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,3) .. "'" .. raw:sub(4,5) .. ctx.input:sub(seg._end + 1, -1)
   elseif preedit:match("^[a-z][a-z][a-z][ '][a-z][a-z]$") or input:match("^[a-z][a-z][a-z]'[a-z][a-z]$") then  -- 3-2
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,2) .. "'" .. raw:sub(3,5) .. ctx.input:sub(seg._end + 1, -1)
   elseif preedit:match("^[a-z][a-z][a-z][ '][a-z][a-z][a-z]$") or input:match("^[a-z][a-z][a-z]'[a-z][a-z][a-z]$") then -- 3-3
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,2) .. "'" .. raw:sub(3,4) .. "'" .. raw:sub(5,6) .. ctx.input:sub(seg._end + 1, -1)
   elseif preedit:match("^[a-z][a-z][ '][a-z][a-z][ '][a-z][a-z]$") or input:match("^[a-z][a-z]'[a-z][a-z]'[a-z][a-z]$") then  -- 2-2-2
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,3) .. "'" .. raw:sub(4,6) .. ctx.input:sub(seg._end + 1, -1)
   elseif preedit:match("^[a-z][a-z][ '][a-z][a-z][ '][a-z][a-z][a-z]$") or input:match("^[a-z][a-z]'[a-z][a-z]'[a-z][a-z][a-z]$") then  -- 2-2-3
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,2) .. "'" .. raw:sub(3,5) .. "'" .. raw:sub(6,7) .. ctx.input:sub(seg._end + 1, -1)
   elseif preedit:match("^[a-z][a-z][ '][a-z][a-z][a-z][ '][a-z][a-z]$") or input:match("^[a-z][a-z]'[a-z][a-z][a-z]'[a-z][a-z]$") then  -- 2-3-2
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,3) .. "'" .. raw:sub(4,5) .. "'" .. raw:sub(6,7) .. ctx.input:sub(seg._end + 1, -1)
   elseif preedit:match("^[a-z][a-z][a-z][ '][a-z][a-z][ '][a-z][a-z]$") or input:match("^[a-z][a-z][a-z]'[a-z][a-z]'[a-z][a-z]$") then  -- 3-2-2
      ctx.input = ctx.input:sub(1, seg._start) .. raw:sub(1,2) .. "'" .. raw:sub(3,4) .. "'" .. raw:sub(5,7) .. ctx.input:sub(seg._end + 1, -1)
   end

   return kAccepted
end

return {
   init = function(env)
      env.processors = {
         semicolon_processor,
         force_segmentation_processor,
      }
   end,

   fini = function(env)
   end,

   func = function(key_event, env)
      if key_event:release() then
         return kNoop
      end

      for _, processor in pairs(env.processors) do
         local res = processor(key_event, env)
         if res == kAccepted or res == kRejected then
            return res
         end
      end
      return kNoop
   end
}
