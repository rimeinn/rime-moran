-- moran_disable_phrase_memory.lua
-- Version: 0.1
-- License: MIT
-- Author: ksqsf
--
-- 將 phrase 和 user_phrase 轉換爲 SimpleCandidate 禁止更新用戶詞庫和詞頻。
return function(t_input, env)
   for original in t_input:iter() do
      if original.type == "phrase" or original.type == "user_phrase" then
         local cand = Candidate("nomem",
                                original._start,
                                original._end,
                                original.text,
                                original.comment)
         yield(cand)
      else
         yield(original)
      end
   end
end
