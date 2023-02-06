local M = {}

local name = "Keyboard"
local msg = require("rosetta.message")

M.current_keyboard = nil -- Default

-- Reset to original settings
local function reset()
   vim.bo.keymap = nil
   vim.o.revins = M.config.options.rtl
end

--- View keys for current mapping
function M.view_keymap()
   local lang = M.current_keyboard

   if lang ~= nil then
      vim.cmd(string.format("vsplit $VIMRUNTIME/keymap/%s.vim", M.config.lang[lang].keymap))

      -- Make it legible
      vim.o.rightleft = M.config.options.rtl
   else
      msg.info(name, "You can only look up mappings on non-default keymaps.")
   end
end

--- Reset keyboard
-- @param silent boolean true: no output message
function M.reset_keyboard(silent)
   reset()
   if M.config.module.keyboard.intuitive_delete then
      vim.keymap.del("i", "<BS>", { buffer = true })
      vim.keymap.del("i", "<Del>", { buffer = true })
   end
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
      M.current_keyboard = lang

      reset()

      -- Get language settings
      local lang_conf = M.config.lang[lang]

      -- Adjust settings
      vim.bo.keymap = lang_conf.keymap
      vim.o.revins = lang_conf.rtl

      -- Swap <Del> and <BS> for more intuitive deleting.
      if M.config.module.keyboard.intuitive_delete then
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

   -- Create user commands
   if M.config.module.keyboard.user_commands then
      for lang, _ in pairs(M.config.lang) do
         local cmd_name =
            string.format("Keyboard%s%s", lang:sub(1, 1):upper(), lang:sub(2))
         vim.api.nvim_create_user_command(
            cmd_name,
            function() M.set_keyboard(lang, M.config.module.keyboard.silent) end,
            {}
         )
      end

      vim.api.nvim_create_user_command(
         "KeyboardReset",
         function() M.reset_keyboard(M.config.module.keyboard.silent) end,
         {}
      )

      vim.api.nvim_create_user_command(
         "KeyboardMappings",
         function() M.view_keymap() end,
         {}
      )
   end
end

return M
