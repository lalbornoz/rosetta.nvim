local M = {}

local config = require("rosetta.config")

--- Initialize and configure Rosetta
-- @tparam ?table opts Options which the user can configure.
-- @usage require("rosetta").setup({opts})
-- @see rosetta.config
function M.setup(opts)
   config.configure(opts)

   if config.options.bidi.enabled then require("rosetta.bidi").init() end
   if config.options.keyboard.enabled then
      require("rosetta.keyboard").init()
   end
end

return M
