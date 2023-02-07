----------
-- Bidirectional (bidi) handling in Rosetta.
-- @module bidi

local M = {}

local name = "Bidi"
local kbd = require("rosetta.keyboard")
local msg = require("rosetta.message")

--- A list of the IDs of buffers with bidi enabled.
-- Key: ID of the Buffer
-- Value: Boolean. If true, buffer is RTL.
M.active_bufs = {}

--- Send content to fribidi CLI
-- @tparam string|table stdin Content to bidi-tize, either a string or a table of lines
-- @string dir Base Direction for bidi'd content
-- @tparam ?string args Extra arguments passed to fribidi
-- @treturn table Bidi'd lines from the buffer
function M.fribidi(content, rtl, args)
   local args = args or ""
   local dir = rtl and "rtl" or "ltr"

   if type(content) == "table" then
      content = vim.tbl_map(
         function(line) return line:gsub([[']], [['\'']]) end,
         content
      )
      content = table.concat(content, "\n")
   end

   return vim.fn.systemlist(
      [[echo ']]
         .. content
         .. [[' | fribidi --nobreak --nopad --]]
         .. dir
         .. " "
         .. args
   )
end

--- Display bidi text in current buffer
-- @bool rtl When true, the base direction is RTL.
function M.buf_enable_bidi(rtl)
   local bufnr = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(bufnr)] == nil then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      lines = M.fribidi(lines, rtl)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      M.active_bufs[tostring(bufnr)] = rtl
   else
      msg.error(name, "Buffer is already bidi'd.")
   end
end

--- Stop displaying bidi text in current buffer
function M.buf_disable_bidi()
   local bufnr = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(bufnr)] ~= nil then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      lines = M.fribidi(lines, M.active_bufs[tostring(bufnr)])
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      M.active_bufs[tostring(bufnr)] = nil
   else
      msg.error(name, "Buffer is already unbidi'd.")
   end
end

--- Convert current buffer contents to bidi
-- This will toggle the text between bidi and udi as a static file.
-- @bool rtl When true, the base direction is RTL.
-- @bool silent boolean When true, Rosetta does not output a message.
function M.buf_run_fribidi(rtl, silent)
   local bufnr = vim.api.nvim_win_get_buf(0)
   vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(bufnr, dir))
   if not silent then msg.info(name, "Ran fribidi on buffer.") end
end

--- Initialize bidi capabilities
function M.init()
   M.config = require("rosetta").config

   local default_rtl = M.config.lang[M.config.options.default].rtl

   -- Autocommand for saving
   if M.config.bidi.revert_before_saving then
      vim.api.nvim_create_autocmd({ "BufWritePre", "BufWritePost" }, {
         callback = function(args)
            if M.active_bufs[tostring(args.buf)] ~= nil then
               local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
               lines = M.fribidi(lines, M.active_bufs[tostring(args.buf)])
               vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
            end
         end,
         group = require("rosetta").augroup,
      })
   end

   -- Autocommand for pasting
   vim.api.nvim_create_autocmd("TextYankPost", {
      pattern = "*",
      callback = function(args)
         local content = vim.fn.getreg(M.config.bidi.register)

         local rtl = M.active_bufs[tostring(bufnr)] or default_rtl

         content = M.fribidi(content) -- Needs to call separately for some reason
         vim.fn.setreg(M.config.bidi.register, content)
      end,
      group = require("rosetta").augroup,
   })

   vim.api.nvim_create_user_command(
      "BidiEnable",
      function() M.buf_enable_bidi(default_rtl) end,
      {}
   )

   vim.api.nvim_create_user_command("BidiDisable", M.buf_disable_bidi, {})

   vim.api.nvim_create_user_command(
      "BidiEnableLTR",
      function() M.buf_enable_bidi(false) end,
      {}
   )

   vim.api.nvim_create_user_command(
      "BidiEnableRTL",
      function() M.buf_enable_bidi(true) end,
      {}
   )
end

return M
