local M = {}

function M.error(module, msg)
   vim.notify(
      string.format("Rosetta (%s): %s", module, msg),
      vim.log.levels.ERROR,
      { title = "Rosetta" }
   )
end

function M.info(module, msg)
   vim.notify(
      string.format("Rosetta (%s): %s", module, msg),
      vim.log.levels.INFO,
      { title = "Rosetta" }
   )
end

return M
