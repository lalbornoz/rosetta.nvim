local M = {}

local bidi = require("rosetta.bidi")
local kbd = require("rosetta.keyboard")
local msg = require("rosetta.message")

M.config = {
   options = {
      rtl = false, -- Default text direction is LTR
   },
   module = {
      bidi = {
         enabled = true,
         user_commands = true, -- Generate usercommands for bidi functions
         revert_before_saving = true, -- Disable bidi-mode before saving buffer contents.
         auto_switch_keyboard = true, -- Automatically switch to the correct RTL language.
      },
      keyboard = {
         enabled = true,
         user_commands = true, -- Generate usercommands for keyboard functions
         silent = false, -- Notify the user when keyboard is switched.
      },
   },
   lang = {}, -- Place language instances here.
}

function M.setup(opts)
   M.config = vim.tbl_deep_extend("force", M.config, opts or {})

   -- Set options
   vim.o.allowrevins = true

   if M.config.module.bidi.enabled then bidi.init() end
   if M.config.module.keyboard.enabled then kbd.init() end
end

return M
