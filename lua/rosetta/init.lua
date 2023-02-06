----------
-- Initialization and configuration of Rosetta.
-- @module rosetta

local M = {}

local bidi = require("rosetta.bidi")
local kbd = require("rosetta.keyboard")
local msg = require("rosetta.message")

--- The default configuration
M.config = {
   options = {
      default = "english", -- Default language
   },
   bidi = {
      enabled = true,
      user_commands = true, -- Generate usercommands for bidi functions
      revert_before_saving = true, -- Disable bidi-mode before saving buffer contents.
   },
   keyboard = {
      enabled = true,
      user_commands = true, -- Generate usercommands for keyboard functions
      auto_switch_keyboard = true, -- Automatically switch to the language under the cursor.
      intuitive_delete = true, -- Swap `Delete` and `Backspace` keys in insert mode for RTL languages.
      silent = false, -- Notify the user when keyboard is switched.
   },
   lang = { -- Place language instances here.
      english = {
         keymap = "",
         rtl = false,
         unicode_range = { "0020-007F" },
      },
   },
}

--- Initialize and configure Rosetta
-- @tparam ?table opts Options which the user can configure.
-- @usage require("rosetta").setup({opts})
-- @see rosetta.config
function M.setup(opts)
   M.config = vim.tbl_deep_extend("force", M.config, opts or {})

   if M.config.bidi.enabled then bidi.init() end
   if M.config.keyboard.enabled then kbd.init() end
end

return M
