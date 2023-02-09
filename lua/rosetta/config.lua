local M = {}

--- The default configuration
local defaults = {
   bidi = {
      enabled = true,
      user_commands = true, -- Generate usercommands for bidi functions.
      intuitive_delete = true, -- Swap `Delete` and `Backspace` keys in insert mode for RTL languages in a bidi buffer.
      register = "b", -- Register which will paste bidi content.
      revert_before_saving = true, -- Disable bidi-mode before saving buffer contents.
   },
   keyboard = {
      enabled = true,
      user_commands = true, -- Generate usercommands for keyboard functions.
      silent = false, -- Notify the user when keyboard is switched.
   },
   lang = { -- Place language instances here.
      default = "english", -- Default language specified.
      english = {
         keymap = "",
         rtl = false,
         unicode_range = { "0020-007F" },
      },
   },
}

function M.configure(opts)
   M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
