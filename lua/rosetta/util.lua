local M = {}

local c = require("rosetta.config").options
local name = "Util"
local msg = require("rosetta.message")

--- Detect current language of a word
-- @string word The word to analyze. Should have only one language!
function M.detect_lang(word)
   for lang, _ in pairs(c.lang) do
      if lang ~= "default" then
         local uni = c.lang[lang].unicode_range
         local unicode_regex = ""
         for _, range in ipairs(uni) do
            unicode_regex = unicode_regex
            .. string.format(
            "[\\u%s-\\u%s]",
            range:sub(1, 4),
            range:sub(6, -1)
         )
         .. "\\|"
         end
         unicode_regex = vim.regex(unicode_regex:sub(1, -3))
         if unicode_regex:match_str(word) ~= nil then
            return lang
         end
      end
   end

   -- If no language was detected, return default language
   return c.lang.default
end

return M