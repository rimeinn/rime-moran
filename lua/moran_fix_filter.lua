-- Moran Fix Filter
-- Copyright (c) 2024 ksqsf
--
-- Ver: 0.2.0
--
-- This file is part of Project Moran
-- Licensed under GPLv3
--
-- 0.2.0: Add `fix_use_dict` option to use "moran_fixed", just like "moran".
--        The old way is still kept, but deprecated and discouraged.
--
-- 0.1.0: added.

local moran = require("moran")
local Top = {}

function Top.init(env)
   env.fix_use_dict = env.engine.schema.config:get_bool("moran/fix/use_dict") or false
   if env.fix_use_dict then
      env.fixed = Component.Translator(env.engine, "", "table_translator@fixed")
      env.use_dict_max_length = env.engine.schema.config:get_int("moran/fix/use_dict_max_length") or 3
   end
   -- At most THRESHOLD smart candidates are subject to reordering,
   -- for performance's sake.
   env.reorder_threshold = 200
   env.quick_code_indicator = env.engine.schema.config:get_string("moran/quick_code_indicator") or "⚡️"
   env.cache = {}
end

function Top.fini(env)
   env.cache = nil
   collectgarbage()
end

function Top.func(t_input, env)
   if env.fix_use_dict then
      return Top.func_use_dict(t_input, env)
   else
      return Top.func_no_dict(t_input, env)
   end
end

function Top.func_use_dict(t_input, env)
   local context = env.engine.context
   local composition = context.composition
   local segment = composition:back()
   local input = context.input:sub(segment._start + 1, segment._end)

   if #input > env.use_dict_max_length then
      for c in t_input:iter() do
         yield(c)
      end
      return
   end

   local fixed_res = env.fixed:query(input, segment)
   local fixed_cands = {}
   local reorder_number = 0
   if fixed_res then
      for fc in fixed_res:iter() do
         fc.comment = env.quick_code_indicator
         table.insert(fixed_cands, fc)
         if utf8.len(fc.text) == 1 then
            reorder_number = reorder_number + 1
            -- log.error('1 insert fixed cand: ' .. tostring(fc.text))
         end
      end
   end
   -- log.error('reorder_number = ' .. tostring(reorder_number))

   local smart_iter = moran.iter_translation(t_input)
   local smart_cands = {}
   for i = 1, env.reorder_threshold do
      if reorder_number == 0 then
         -- log.error('all matched, break')
         break
      end
      -- log.error('still ' .. tostring(reorder_number) .. ' to match')

      local sc = smart_iter()
      if sc == nil then
         break
      end
      -- log.error('get sc = ' .. tostring(sc.text))

      local found = false
      for j = 1, #fixed_cands do
         if utf8.len(sc.text) == 1 and fixed_cands[j].text == sc.text then
            fixed_cands[j] = sc
            fixed_cands[j].comment = fixed_cands[j].comment..env.quick_code_indicator
            found = true
            reorder_number = reorder_number - 1
            -- log.error('matched fc=' ..fixed_cands[j].text.. ' with sc=' .. sc.text .. ' at j=' .. tostring(j))
            break
         end
      end
      if not found then
         table.insert(smart_cands, sc)
      end
   end

   for _, c in pairs(fixed_cands) do
      yield(c)
   end
   for _, c in pairs(smart_cands) do
      yield(c)
   end
   for c in smart_iter do
      yield(c)
   end
end

function Top.func_no_dict(t_input, env)
   local input = env.engine.context.input
   local input_len = utf8.len(input)

   -- 只支持一二簡
   if input_len > 2 then
      for cand in t_input:iter() do
         yield(cand)
      end
      return
   end

   local needle = Top.get_needle(env, input)
   if needle == nil or needle == "" then
      for cand in t_input:iter() do
         yield(cand)
      end
      return
   end

   local threshold = env.reorder_threshold
   local stash = {}
   local iter = moran.iter_translation(t_input)
   local found = nil
   for cand in iter do
      if cand:get_genuine().type == "punct" then
         yield(cand)
         goto continue
      end

      if cand.text == needle then
         found = cand
         break
      elseif threshold > 0 then
         threshold = threshold - 1
         table.insert(stash, cand)
      else
         table.insert(stash, cand)
         break
      end

      ::continue::
   end

   if found then
      found:get_genuine().comment = env.quick_code_indicator
      yield(found)
   end

   for i, cand in pairs(stash) do
      yield(cand)
   end

   for cand in iter do
      yield(cand)
   end
end

function Top.get_needle(env, input)
   if env.cache[input] then
      return env.cache[input]
   end
   if input:find("/") then
      return nil
   end
   local val = env.engine.schema.config:get_string("moran/fix/" .. input)
   env.cache[input] = val
   return val
end

return Top
