----------
-- Keyboard handling in Rosetta.
-- @module keyboard

local M = {}

-- Auto keyboard
M.auto = false

-- Save defaults for any settings changed by a keyboard for easy reversion
local defaults = {}
local active_autocmds = {} -- List of autocommands currently active

local name = "Keyboard"
local msg = require("rosetta.message")

-- Reset to original settings
local function reset()
   -- Revert settings
   vim.bo.keymap = M.config.lang[M.config.options.default].keymap
   vim.o.revins = M.config.lang[M.config.options.default].rtl

   for option, setting in pairs(defaults) do
      vim.o[option] = setting
   end

   -- This is messy at the moment.
   -- I'd rather find a more elegant way, i.e., deleting the keymaps.
   -- But to do that, I need to check whether they exist at all.
   if M.config.keyboard.intuitive_delete then
      vim.keymap.set("i", "<BS>", "<BS>", { buffer = true })
      vim.keymap.set("i", "<Del>", "<Del>", { buffer = true })
   end
end

--- View keys for current mapping
-- This creates a vsplit with vim's keymap for the current language displayed.
function M.view_keymap()
   if vim.bo.keymap ~= "" then
      vim.cmd(string.format("vsplit $VIMRUNTIME/keymap/%s.vim", vim.bo.keymap))
   else
      msg.info(
         name,
         string.format(
            "The current language does not have a keymap.",
            vim.bo.keymap
         )
      )
   end

   -- Make it legible
   vim.o.rightleft = M.config.lang[M.config.options.default].rtl
end

--- Set keyboard to desired language
-- @string lang The name of the language.
-- @bool silent When true, Rosetta does not inform the user of the switch.
function M.set_keyboard(lang, silent)
   -- See if language is configured
   if vim.tbl_get(M.config.lang, lang) == nil then
      msg.error(
         name,
         string.format("Could not find '%s' in configured languages.", lang)
      )
   else
      reset() -- Reset keyboard

      -- Get language settings
      local lang_conf = M.config.lang[lang]

      -- Adjust settings
      vim.bo.keymap = lang_conf.keymap
      vim.o.revins = lang_conf.rtl

      if lang_conf.options ~= nil then
         for option, setting in pairs(lang_conf.options) do
            defaults[option] = vim.o[option]
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

--- Toggle auto keyboard capabilities
-- @bool enabled When true, auto-switching is enabled.
-- @bool silent When true, Rosetta does not inform the user of the switch.
function M.auto_keyboard(enable, silent)
   local bufnr = vim.api.nvim_win_get_buf(0)

   M.auto = enable

   if enable then
      -- Switch source when entering insert mode
      local autocmd_id = vim.api.nvim_create_autocmd("InsertEnter", {
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
               if unicode_regex:match_str(sample) ~= nil then
                  M.set_keyboard(lang, true)
                  break
               end
            end
         end,
         group = M.augroup,
      })

      active_autocmds["insert_auto_switch"] = autocmd_id
   else
      -- Remove autocmd for switching
      if active_autocmds["insert_auto_switch"] ~= nil then
         vim.api.nvim_del_autocmd(active_autocmds["insert_auto_switch"])
         active_autocmds["insert_auto_switch"] = nil
      end
   end

   if not silent then
      local on_msg = enable and "activated" or "deactivated"
      msg.info(name, string.format("Auto-switching keyboard is %s.", on_msg))
   end
end

--- Initialize keyboard capabilities
function M.init()
   M.config = require("rosetta").config
   M.augroup = vim.api.nvim_create_augroup("RosettaKeyboard", { clear = true })

   -- Set options and default keyboard
   vim.o.allowrevins = true
   M.set_keyboard(M.config.options.default, true)

   -- Create user commands
   if M.config.keyboard.user_commands then
      -- Keyboard switch commands
      for lang, _ in pairs(M.config.lang) do
         local cmd_name =
            string.format("Keyboard%s%s", lang:sub(1, 1):upper(), lang:sub(2))
         vim.api.nvim_create_user_command(cmd_name, function()
            M.auto_keyboard(false, true) -- Disable auto-keyboard when user switches
            M.set_keyboard(lang, M.config.keyboard.silent)
         end, {})
      end

      -- Auto keyboard
      vim.api.nvim_create_user_command(
         "KeyboardAutoEnable",
         function() M.auto_keyboard(true, false) end,
         {}
      )

      vim.api.nvim_create_user_command(
         "KeyboardAutoDisable",
         function() M.auto_keyboard(false, false) end,
         {}
      )

      -- View mappings
      vim.api.nvim_create_user_command(
         "KeyboardMappings",
         function() M.view_keymap() end,
         {}
      )
   end
end

return M
