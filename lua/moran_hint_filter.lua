-- Moran Translator (for Express Editor)
-- Copyright (c) 2023-2026 ksqsf
--
-- Ver: 0.4.0
--
-- This file is part of Project Moran
-- Licensed under GPLv3
--
-- 0.4.0: 適配多字詞重排。
--
-- 0.3.0: 增加 quick_code_hint_indicator 選項
--
-- 0.2.0: 若開啓 inject_fixed_words ，則提示長詞
--
-- 0.1.0: 合併原 moran_aux_hint 和 moran_quick_code_hint
--
local moran = require("moran")
local Module = {}

function Module.init(env)
   env.enable_aux_hint = env.engine.schema.config:get_bool("moran/enable_aux_hint")
   if env.enable_aux_hint then
      env.aux_table = moran.load_zrmdb()
      if not env.aux_table then
         env.enable_aux_hint = false
      end
   else
      env.aux_table = nil
   end

   env.is_auxfilter = env.name_space == "auxfilter"
   env.enable_quick_code_hint = env.engine.schema.config:get_bool("moran/enable_quick_code_hint")
   -- 輔篩模式禁止簡碼提示
   if env.enable_quick_code_hint and not env.is_auxfilter then
      -- The user might have changed it.
      local dict = env.engine.schema.config:get_string("fixed/dictionary")
      env.quick_code_hint_reverse = ReverseLookup(dict)
      env.quick_code_hint_skip_chars = env.engine.schema.config:get_bool("moran/quick_code_hint_skip_chars") or false
   else
      env.quick_code_hint_reverse = nil
   end
   env.quick_code_hint_indicator = env.engine.schema.config:get_string("moran/quick_code_hint_indicator")
   if env.quick_code_hint_indicator == nil then
      env.quick_code_hint_indicator = env.engine.schema.config:get_string("moran/quick_code_indicator")
   end

   -- 若開啓 inject_fixed_words，則可以提示長詞（>=3）
   env.inject_fixed_words = env.engine.schema.config:get_bool("moran/inject_fixed_words") or false
   -- NOTE: 暫不提示二字詞
end

function Module.fini(env)
   env.enable_aux_hint = false
   env.aux_table = nil
   env.enable_quick_code_hint = nil
   env.quick_code_hint_reverse = nil
   collectgarbage()
end

function Module.get_auxcode_hint(env, cand, gcand)
   if not env.enable_aux_hint or not env.aux_table then
      return nil
   end
   local text = gcand.text
   local len = utf8.len(text)
   if len == 1 then
      local cp = utf8.codepoint(text)
      local codes = env.aux_table[cp]
      if not codes then
         return nil
      end
      return codes:sub(2)
   elseif len ~= 1 and env.is_auxfilter and (gcand.type == "phrase" or gcand.type == "user_phrase") then
      result = ""
      for i, cp in moran.codepoints(gcand.text) do
         local cpaux = env.aux_table[cp]
         if cpaux and #cpaux > 0 then
            cpaux = cpaux:match("^[a-z]+")  -- 取第一个
            if result == "" then
               result = cpaux
            else
               result = result .. ' ' .. cpaux
            end
         else
            return nil
         end
      end
      if #result == 0 then
         return nil
      end
      return result
   else
      return nil
   end
end

function Module.get_quickcode_hint(env, cand, gcand)
   if not env.enable_quick_code_hint or not env.quick_code_hint_reverse then
      return nil
   end
   local text = gcand.text
   local len = utf8.len(text)
   if len == 1 and env.quick_code_hint_skip_chars then
      return nil
   end
   local all_codes = env.quick_code_hint_reverse:lookup(text)
   if not all_codes then
      return nil
   end
   local in_use = false
   local codes = {}
   for code in all_codes:gmatch("%S+") do
      if #code < 4 or (env.inject_fixed_words and len >= 3) then
         if code == cand.preedit:gsub("%s", "") then
            in_use = true
         else
            table.insert(codes, code)
         end
      end
   end
   if #codes == 0 and not in_use then
      return nil
   end
   local codes_hint = table.concat(codes, " ")
   if #codes_hint == 0 then
      return nil
   end
   return codes_hint
end

function Module.func(translation, env)
   if not env.enable_aux_hint and not env.enable_quick_code_hint then
      for cand in translation:iter() do
         yield(cand)
      end
      return
   end

   local major_sep = " ¦ "
   local minor_sep = env.quick_code_hint_indicator
   if #minor_sep == 0 then
      minor_sep = major_sep
   end
   for cand in translation:iter() do
      if cand.type == "punct" then
         yield(cand)
         goto continue
      end
      local gcand = cand:get_genuine()
      local auxhint = Module.get_auxcode_hint(env, cand, gcand)
      local qchint = Module.get_quickcode_hint(env, cand, gcand)
      if auxhint and qchint then
         local hint = auxhint .. minor_sep .. qchint
         if #gcand.comment == 0 or gcand.comment == env.quick_code_hint_indicator then
            gcand.comment = hint
         else
            gcand.comment = gcand.comment .. major_sep .. hint
         end
      elseif auxhint then
         if not env.is_auxfilter and #gcand.comment == 0 then
            -- 單字，不額外添加 sep
            -- 同時包括了 quick_code_hint_indicator == "" 情況
            gcand.comment = auxhint
         elseif not env.is_auxfilter and (gcand.comment == env.quick_code_hint_indicator) then
            -- 單字，已有 sep ，把 hint 添加到 sep 前面
            gcand.comment = auxhint .. gcand.comment
         else
            -- 輔篩模式，不論單字還是詞組都加上 ¦
            gcand.comment = gcand.comment .. major_sep .. auxhint
         end
      elseif qchint then
         if #gcand.comment == 0 then
            gcand.comment = gcand.comment .. env.quick_code_hint_indicator .. qchint
         elseif gcand.comment == env.quick_code_hint_indicator then
            -- 已有 sep ，不再加
            gcand.comment = gcand.comment .. qchint
         else
            gcand.comment = gcand.comment .. major_sep .. env.quick_code_hint_indicator .. qchint
         end
      end
      yield(cand)
      ::continue::
   end
end

return Module
