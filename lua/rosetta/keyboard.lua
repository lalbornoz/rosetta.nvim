local M = {}

local name = "Keyboard"
local msg = require("rosetta.message")

-- Reset to original settings
local function reset()
   vim.bo.keymap = M.config.lang[M.config.options.default].keymap
   vim.o.revins = M.config.lang[M.config.options.default].rtl
end

--- View keys for current mapping
function M.view_keymap()
   if vim.bo.keymap ~= "" then
      vim.cmd(string.format("vsplit $VIMRUNTIME/keymap/%s.vim", M.config.lang[lang].keymap))
   else
      msg.info(name, string.format("The current language does not have a keymap.", vim.bo.keymap))
   end

   -- Make it legible
   vim.o.rightleft = M.config.lang[M.config.options.default].rtl
end

--- Reset keyboard
-- @param silent boolean true: no output message
function M.reset_keyboard(silent)
   if vim.wo.rightleft and M.config.keyboard.intuitive_delete then
      vim.keymap.del("i", "<BS>", { buffer = true })
      vim.keymap.del("i", "<Del>", { buffer = true })
   end
   reset()
   if not silent then msg.info(name, "Reset keyboard") end
end

--- Set keyboard to desired language
-- @param lang the name of the language
-- @param silent boolean true: no output message
function M.set_keyboard(lang, silent)
   -- See if language is configured
   if vim.tbl_get(M.config.lang, lang) == nil then
      msg.error(
         string.format("Could not find '%s' in configured languages.", lang)
      )
   else
      reset()

      -- Get language settings
      local lang_conf = M.config.lang[lang]

      -- Adjust settings
      vim.bo.keymap = lang_conf.keymap
      vim.o.revins = lang_conf.rtl

      if lang_conf.options ~= nil then
         for option, setting in pairs(lang_conf.options) do
            vim.o[option] = setting
         end
      end

      -- Swap <Del> and <BS> for more intuitive deleting.
      if lang_conf.rtl and M.config.keyboard.intuitive_delete then
         vim.keymap.set("i", "<BS>", "<Del>", { buffer = true })
         vim.keymap.set("i", "<Del>", "<BS>", { buffer = true })
      end

      if not silent then
         msg.info(name, string.format("Switched to '%s'", lang))
      end
   end
end

--- Initialize keyboard capabilities
function M.init()
   M.config = require("rosetta").config

   -- Set options and default keyboard
   vim.o.allowrevins = true
   M.set_keyboard(M.config.options.default, true)

   -- Autocommands for insert mode.
   if M.config.keyboard.auto_switch_keyboard then
      vim.api.nvim_create_autocmd("InsertEnter", {
         callback = function(args)
            -- Get current word under cursor
            local sample = vim.fn.expand("<cword>")

            -- Find which language it is via unicode
            for lang, _ in pairs(M.config.lang) do
               local uni = M.config.lang[lang].unicode_range
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
               if
                  unicode_regex:match_str(sample) ~= nil
               then
                  M.set_keyboard(lang, true)
                  break
               end
            end
         end,
         group = M.augroup,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
         callback = function(args)
            if vim.bo.keymap ~= nil then
               M.reset_keyboard(true)
            end
         end,
         group = M.augroup,
      })
   end

   -- Create user commands
   if M.config.keyboard.user_commands then
      for lang, _ in pairs(M.config.lang) do
         local cmd_name =
            string.format("Keyboard%s%s", lang:sub(1, 1):upper(), lang:sub(2))
         vim.api.nvim_create_user_command(
            cmd_name,
            function() M.set_keyboard(lang, M.config.keyboard.silent) end,
            {}
         )
      end

      vim.api.nvim_create_user_command(
         "KeyboardMappings",
         function() M.view_keymap() end,
         {}
      )
   end
end

return M
