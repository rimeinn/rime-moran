-- Moran Translator (for Express Editor)
-- Copyright (c) 2023, 2024, 2025 ksqsf
--
-- Ver: 0.12.0
--
-- This file is part of Project Moran
-- Licensed under GPLv3
--
-- 0.12.0: 引入惰性加載
--
-- 0.11.0: 引入 quick_code_in_sentence_making 配置項。
-- 該配置項改進了魔然最初的一項設計（造詞時禁止輸出固定選項）以維持造詞能力，
-- 但事實上配合 reorder_filter 可以取消這一限制。
-- (輔篩模式此前的 fix/use_dict 已經實現該功能。)
--
-- 0.10.1: 配合主方案變更的次要修改。
--
-- 0.10.0: 增加 inject_prioritize 支持。
--
-- 0.9.0: show_words_anyway 和 show_chars_anyway 分別更名爲
-- inject_fixed_words 和 inject_fixed_chars。爲保持兼容性，原名還可以
-- 繼續使用（優先級高於新名），但未來可能被刪除。
--
-- 0.8.1: 支持 word_filter_match_indicator。
--
-- 0.8.0: 適配 hint_filter，支持詞輔提前提示。
--
-- 0.7.2: 修正詞輔在三字詞可能不生效的問題。
--
-- 0.7.1: 修正詞輔與整句輔的一處兼容性問題，並優化了性能。
--
-- 0.7.0: 定義 show_words_anyway、show_chars_anyway 和固詞模式同時開啓
-- 時的語義。
--
-- 0.6.1, 0.6.2: show_words_anyway 在四碼時跳過二字詞。
--
-- 0.6.0: 增加 show_chars_anyway 和 show_words_anyway 設置，允許將
-- fixed 碼表的單字全碼放置在第二位，不再需要打全碼。如輸入「jwrg」就
-- 可以在第二位得到「佳」，按分號選取之。
--
-- 0.5.2: 修復與 quick_code_hint 的兼容性問題。
--
-- 0.5.1: 修復「出簡讓全」的性能問題。
--
-- 0.5.0: 修復詞庫維護問題。使用簡碼鍵入的字的字頻，不會被增加到
-- script translator 的用戶詞庫中，導致長時間使用後，生僻字的字頻反而
-- 更高，構詞和整句會被干擾。
--
-- 在方案中引用時，需增加 @with_reorder 標記，並把
-- moran_reorder_filter 添加爲第一個 filter。
--
-- 0.4.2: 修復內存泄露。
--
-- 0.4.0: 增加詞輔功能。
--
-- 0.3.2: 允許用戶自定義出簡讓全的各項設置：是否啓用、延遲幾位候選、是
-- 否顯示簡快碼提示。
--
-- 0.3.1: 允許自定義簡快碼提示符。
--
-- 0.3.0: 增加單字輸出的出簡讓全。
--
-- 0.2.0: 增加固定二字詞模式。
--
-- 0.1.0: 本翻譯器用於解決 Rime 原生的翻譯流程中，多翻譯器會互相干擾、
-- 導致造詞機能受損的問題。以「驚了」造詞爲例：用戶輸入 jym le，選擇第
-- 一個字「驚」後，再選「了」字，這時候將無法造出「驚了」這個詞。這是
-- 因爲「了」是從碼表翻譯器輸出的，在 script 翻譯器的視角看來，並不知
-- 道用戶輸出了「驚了」兩個字，所以造不出詞。
--
-- 目前版本的解決方法是：用戶選過字後，臨時禁用 table 翻譯器，使得
-- script 可以看到所有輸入，從而解決造詞問題。

local moran = require("moran")
local top = {}

local kAny = 0
local kChar = 1
local kWord = 2

function top.init(env)
   -- Rime 組件
   env.fixed = Component.Translator(env.engine, "", "table_translator@fixed")
   env.smart = Component.Translator(env.engine, "", "script_translator@smart")
   env.rfixed = moran.Thunk(function()
         return ReverseLookup(env.engine.schema.config:get_string("fixed/dictionary") or "moran_fixed")
   end)

   -- 簡快碼相關配置項
   env.quick_code_indicator = env.engine.schema.config:get_string("moran/quick_code_indicator") or "⚡️"
   env.quick_code_in_sentence_making = moran.get_config_bool(env, "moran/quick_code_in_sentence_making", true)
   if env.name_space == 'with_reorder' then
      -- `F 表示碼表輸出，會被 reorder_filter 重排
      env.quick_code_indicator = '`F'
   else
      -- 若不啓用 reorder_filter，則不允許造句時產生碼表輸出
      env.quick_code_in_sentence_making = false
   end

   -- 出簡讓全相關配置項
   env.ijrq_enable = env.engine.schema.config:get_bool("moran/ijrq/enable")
   env.ijrq_defer = env.engine.schema.config:get_int("moran/ijrq/defer") or env.engine.schema.config:get_int("menu/page_size") or 5
   env.ijrq_hint = env.engine.schema.config:get_bool("moran/ijrq/show_hint")
   env.ijrq_suffix = env.engine.schema.config:get_string("moran/ijrq/suffix") or 'o'
   env.enable_word_filter = env.engine.schema.config:get_bool("moran/enable_word_filter")
   env.word_filter_match_indicator = env.engine.schema.config:get_string("moran/word_filter_match_indicator")
   env.enable_aux_hint = env.engine.schema.config:get_bool("moran/enable_aux_hint")
   env.inject_fixed_chars = env.engine.schema.config:get_bool("moran/show_chars_anyway") or env.engine.schema.config:get_bool("moran/inject_fixed_chars")
   env.inject_fixed_words = env.engine.schema.config:get_bool("moran/show_words_anyway") or env.engine.schema.config:get_bool("moran/inject_fixed_words")

   local inject_prioritize = env.engine.schema.config:get_string("moran/inject_prioritize")
   if inject_prioritize == 'word' then
      env.inject_prioritize = kWord
   elseif inject_prioritize == 'char' then
      env.inject_prioritize = kChar
   else
      env.inject_prioritize = kAny
   end

   -- quick_code_hint 開啓時出簡讓全不應該輸出 comment，簡碼會由 quick_code_hint 輸出。
   env.enable_quick_code_hint = env.engine.schema.config:get_bool("moran/enable_quick_code_hint") or false
   env.quick_code_indicator_skip_chars = env.engine.schema.config:get_bool("moran/quick_code_indicator_skip_chars") or false

   -- output 狀態
   env.output_i = 0
   env.output_injected_secondary = {}
end

function top.fini(env)
   env.fixed = nil
   env.smart = nil
   env.rfixed = nil
   env.output_injected_secondary = nil
   collectgarbage()
end

function top.func(input, seg, env)
   top.output_begin(env)

   -- 每 10% 的翻譯觸發一次 GC
   if math.random() < 0.1 then
      collectgarbage()
   end

   local input_len = utf8.len(input)
   local inflexible = env.engine.context:get_option("inflexible")
   local indicator = env.quick_code_indicator

   -- 用戶尚未選過字時，調用碼表。
   local is_sentence_making = not (env.engine.context.input == input)
   if not is_sentence_making or env.quick_code_in_sentence_making then
      local fixed_res = env.fixed:query(input, seg)
      -- 如果輸入長度爲 4，只輸出 2 字詞。
      if fixed_res ~= nil then
         if (input_len == 4) then
            if inflexible and env.inject_fixed_words and env.inject_fixed_chars then
               -- 如果固詞, inject_fixed_words 和 inject_fixed_chars 同時打開，則理解爲掛接用法，直接輸出碼表。
               for cand in fixed_res:iter() do
                  top.output_from_fixed(env, cand)
               end
            elseif inflexible and env.inject_fixed_words then
               -- 固詞 + 長詞 = 只有詞
               for cand in fixed_res:iter() do
                  if utf8.len(cand.text) > 1 then
                     top.output_word_from_fixed(env, cand)
                  end
               end
            elseif inflexible and env.inject_fixed_chars then
               -- 固詞 + 單字 = 只有單字和二字詞
               for cand in fixed_res:iter() do
                  local cand_len = utf8.len(cand.text)
                  if cand_len == 1 then
                     top.output_char_from_fixed(env, cand)
                  elseif cand_len == 2 then
                     top.output_word_from_fixed(env, cand)
                  end
               end
            elseif inflexible then
               -- 如果只打開固詞模式，則 *只* 優先輸出 2 字詞
               for cand in fixed_res:iter() do
                  local cand_len = utf8.len(cand.text)
                  if cand_len == 2 then
                     top.output_word_from_fixed(env, cand)
                  end
               end
            else
               -- 否則，什麼都不輸出。
            end
         elseif input_len < 4 then          -- 造句模式下，只使用固定單字（詞語無法固定）
            for cand in fixed_res:iter() do
               if not is_sentence_making or utf8.len(cand.text) == 1 then
                  top.output_from_fixed(env, cand)
               end
            end
         elseif not is_sentence_making then  -- input_len > 4，輸出所有
            for cand in fixed_res:iter() do
               top.output_from_fixed(env, cand)
            end
         end
      end
   end

   local fixed_triggered = env.output_i > 0

   -- 注入到首選後的選項
   -- 目前的用例：在動詞模式下處理 inject_fixed_chars 和 inject_fixed_words
   -- 注意，爲了提高常規情況（inject_prioritize = kAny）的性能，
   -- (1) 在此種情況下，下面的代碼會直接修改 env.output_injected_secondary
   -- (2) inject_prioritize != kAny 時會先把結果寄存在 inject_chars 和 inject_words 中
   --     在遍歷完成後才得到 env.output_injected_secondary
   env.output_injected_secondary = {}
   local inject_has_priority = env.inject_prioritize and (env.inject_prioritize ~= kAny)
   local inject_chars = {}  -- valid only when inject_has_priority
   local inject_words = {}  -- valid only when inject_has_priority
   local num_injections = 0 -- valid only when inject_has_priority
   if (not fixed_triggered and input_len == 4) then
      for cand in moran.query_translation(env.fixed, input, seg, nil) do
         local cand_len = utf8.len(cand.text)
         if (env.inject_fixed_chars and cand_len == 1) or (env.inject_fixed_words and cand_len > 2) then
            if cand_len ~= 1 or (cand_len == 1 and not env.quick_code_indicator_skip_chars) then
               cand:get_genuine().comment = indicator
            end
            if not inject_has_priority then
               table.insert(env.output_injected_secondary, cand)
            else
               num_injections = num_injections + 1
               if cand_len == 1 then
                  inject_chars[num_injections] = cand
               else
                  inject_words[num_injections] = cand
               end
            end
         end
      end
   end
   if inject_has_priority then
      if env.inject_prioritize == kChar then
         env.output_injected_secondary = top.append_lists(num_injections, inject_chars, inject_words)
      elseif env.inject_prioritize == kWord then
         env.output_injected_secondary = top.append_lists(num_injections, inject_words, inject_chars)
      else
         log.error("env.inject_prioritize has an invalid value: " .. tostring(env.inject_prioritize))
      end
   end

   -- 詞輔在正常輸出之前，以提高其優先級
   if env.enable_word_filter and (input_len == 5 or input_len == 7) then
      local real_input = input:sub(1, input_len - 1)
      local user_ac = input:sub(input_len, input_len)
      local iter = top.raw_query_smart(env, real_input, seg, true)
      for cand in iter do
         local len_match = (input_len == 7 and #cand.preedit == 8) or (input_len == 5 and #cand.preedit == 5)
         local idx = len_match and cand.comment:find(user_ac)
         local only_sp = (cand.preedit:sub(3,3) == ' ') and (#cand.preedit < 6 or cand.preedit:sub(6,6) == ' ')
         if only_sp and idx then
            cand._end = cand._end + 1
            cand.preedit = input
            if env.word_filter_match_indicator then
               cand.comment = env.word_filter_match_indicator
            end
            top.output(env, cand)
         end
         if #cand.preedit <= 2 then
            break
         end
      end
   end

   -- smart 在 fixed 之後輸出。
   -- 當需要詞輔時，保留 comment，以「提前」（用戶輸入詞輔前）提示輔助碼。
   local smart_iter = top.raw_query_smart(env, input, seg, env.enable_word_filter and env.enable_aux_hint)
   if smart_iter ~= nil then
      local ijrq_enabled = env.ijrq_enable
         and (env.engine.context.input == input)
         and ((input_len == 4) or (input_len == 5 and input:sub(5,5) == env.ijrq_suffix))
      if not ijrq_enabled then
         -- 不啓用出簡讓全時
         for cand in smart_iter do
            top.output(env, cand)
         end
      else
         -- 啓用出簡讓全時
         local immediate_set = {}
         local deferred_set = {}
         for cand in smart_iter do
            local defer = false
            -- 如果輸出有詞，說明在拼詞，用戶很可能要使用高頻字，故此時停止出簡讓全。
            if (ijrq_enabled and utf8.len(cand.text) > 1) then
               ijrq_enabled = false
            end
            if (ijrq_enabled and utf8.len(cand.text) == 1) then
               local fixed_codes = env.rfixed():lookup(cand.text)
               for code in fixed_codes:gmatch("%S+") do
                  if #code < 4
                     and string.sub(input, 1, #code) == code
                  then
                     defer = true
                     if env.ijrq_hint and cand.preedit:sub(1,4) == input:sub(1,4) and not env.enable_quick_code_hint then
                        cand.comment = code
                     end
                     break
                  end
               end
            end
            if (not defer) then
               table.insert(immediate_set, cand)
            else
               table.insert(deferred_set, cand)
            end
         end
         for i = 1, math.min(env.ijrq_defer, #immediate_set) do
            top.output(env, immediate_set[i])
         end
         for i = 1, #deferred_set do
            top.output(env, deferred_set[i])
         end
         for i = math.min(env.ijrq_defer, #immediate_set) + 1, #immediate_set do
            top.output(env, immediate_set[i])
         end
      end
   end

   -- 最后：如果 smart 輸出爲空，並且 fixed 之前沒有調用過，此時再嘗試調用一下
   if env.output_i == 0 then
      for cand in moran.query_translation(env.fixed, input, seg, nil) do
         if not is_sentence_making or utf8.len(cand.text) == 1 then
            cand.comment = indicator
            yield(cand)
         end
      end
   end
end

-- | 每次 translation 開始前應該初始化 output 狀態
function top.output_begin(env)
   env.output_i = 0
   env.output_injected_secondary = {}
end

-- | 支持候選注入的 yield
function top.output(env, cand)
   -- 注意：需要保證 spelling hint 僅對 3 字以下詞開啓
   yield(cand)
   env.output_i = env.output_i + 1
   if env.output_i == 1 then
      -- drain injected cands
      local cands = env.output_injected_secondary
      env.output_injected_secondary = {}
      for i, c in pairs(cands) do
         top.output(env, c)
      end
   end
end

function top.output_char_from_fixed(env, cand)
   if not env.quick_code_indicator_skip_chars then
      cand.comment = env.quick_code_indicator
   end
   top.output(env, cand)
end

function top.output_word_from_fixed(env, cand)
   cand.comment = env.quick_code_indicator
   top.output(env, cand)
end

function top.output_from_fixed(env, cand)
   if utf8.len(cand.text) == 1 then
      top.output_char_from_fixed(env, cand)
   else
      top.output_word_from_fixed(env, cand)
   end
end

-- | Query the smart translator for input, and transform the comment
-- | for candidates whose length is 2 or 3 characters long.
function top.raw_query_smart(env, input, seg, with_comment)
   local transform = function(cand)
      local cand_len = utf8.len(cand.text)
      if cand_len == 2 or cand_len == 3 then
         if with_comment then
            cand:get_genuine().comment = cand.comment:gsub("[a-z]+;([a-z])[a-z] ?", "%1")
         else
            cand:get_genuine().comment = ""
         end
      else
         cand:get_genuine().comment = ""
      end
      return cand
   end
   return moran.query_translation(env.smart, input, seg, transform)
end

-- Merge non-nil values in l1 and l2 into a new list.
function top.append_lists(max, l1, l2)
   local result = {}
   for i = 1, max do
      if l1[i] ~= nil then
         table.insert(result, l1[i])
      end
   end
   for i = 1, max do
      if l2[i] ~= nil then
         table.insert(result, l2[i])
      end
   end
   return result
end

return top
