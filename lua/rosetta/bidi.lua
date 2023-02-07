----------
-- Bidirectional (bidi) handling in Rosetta.
-- @module bidi

local M = {}

local name = "Bidi"
local kbd = require("rosetta.keyboard")
local msg = require("rosetta.message")

--- A list of the IDs of buffers with bidi enabled.
-- Key: ID of the Buffer
-- Value: String. Buffer's base direction ("rtl"|"ltr")
M.active_bufs = {}

--- Send string to fribidi CLI
-- @string stdin Content to bidi-tize
-- @tparam ?string args Arguments passed to fribidi
-- @treturn table Bidi'd lines from the buffer
function M.fribidi(stdin, args)
   local args = args or ""
   return vim.fn.systemlist(
      [[echo ']] .. stdin .. [[' | fribidi --nobreak --nopad ]] .. args
   )
end

--- Run buffer contents through fribidi
-- @treturn table Bidi'd lines from the buffer
local function bidi_buf(bufnr, dir)
   local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
   lines = vim.tbl_map(
      function(line) return line:gsub([[']], [['\'']]) end,
      lines
   )
   return M.fribidi(table.concat(lines, "\n"), "--" .. dir)
end

--- Display bidi text in current buffer
-- @string dir The base direction to bidi the buffer
function M.buf_enable_bidi(dir)
   local buf_handle = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(buf_handle)] == nil then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(buf_handle, dir))
      M.active_bufs[tostring(buf_handle)] = dir
   end
end

--- Stop displaying bidi text in current buffer
-- @string dir The base direction to bidi the buffer
function M.buf_disable_bidi()
   local buf_handle = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(buf_handle)] ~= nil then
      vim.api.nvim_buf_set_lines(
         0,
         0,
         -1,
         false,
         bidi_buf(buf_handle, M.active_bufs[tostring(buf_handle)])
      )
      M.active_bufs[tostring(buf_handle)] = nil
   end
end

--- Convert current buffer contents to bidi
-- This will toggle the text between bidi and udi as a static file.
-- @bool dir When true, the base direction is RTL.
-- @bool silent boolean When true, Rosetta does not output a message.
function M.buf_run_fribidi(dir, silent)
   local buf_handle = vim.api.nvim_win_get_buf(0)
   vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(buf_handle, dir))
   if not silent then msg.info(name, "Ran fribidi on buffer.") end
end

--- Convert/revert the current line to bidi
-- Automatically takes buffer's current base direction,
-- or if buffer is not active, the default base direction.
function M.line_run_fribidi()
   local linenr = vim.api.nvim_win_get_cursor(0)[1]
   local line = vim.api.nvim_buf_get_lines(0, linenr - 1, linenr, false)[1]

   local dir = ""
   if M.active_bufs[tostring(buf_handle)] ~= nil then
      dir = M.active_bufs[tostring(buf_handle)]
   else
      dir = M.config.lang[M.config.options.default].rtl and "rtl" or "ltr"
   end

   line = M.fribidi(line, "--" .. dir)
   vim.api.nvim_buf_set_lines(0, linenr - 1, linenr, false, line)

   msg.info(name, string.format("Converted line %s.", linenr))
end

--- Initialize bidi capabilities
function M.init()
   M.config = require("rosetta").config

   M.augroup = vim.api.nvim_create_augroup("BidiGrp", { clear = true })

   -- Autocommand for saving
   if M.config.bidi.revert_before_saving then
      vim.api.nvim_create_autocmd({ "BufWritePre", "BufWritePost" }, {
         callback = function(args)
            if M.active_bufs[tostring(args.buf)] ~= nil then
               M.buf_run_fribidi(M.active_bufs[tostring(args.buf)], true)
            end
         end,
         group = M.augroup,
      })
   end

   -- Create user commands

   if M.config.bidi.enabled then
      -- Find default bidi direction
      local default_dir = M.config.lang[M.config.options.default].rtl and "rtl"
         or "ltr"

      vim.api.nvim_create_user_command(
         "BidiLineConvert",
         M.line_run_fribidi,
         {}
      )

      -- Default
      vim.api.nvim_create_user_command(
         "BidiConvert",
         function() M.buf_run_fribidi(default_dir, true) end,
         {}
      )

      vim.api.nvim_create_user_command(
         "BidiEnable",
         function() M.buf_enable_bidi(default_dir) end,
         {}
      )

      vim.api.nvim_create_user_command("BidiDisable", M.buf_disable_bidi, {})

      -- Manual (LTR)
      vim.api.nvim_create_user_command(
         "BidiConvertLTR",
         function() M.buf_run_fribidi("ltr", true) end,
         {}
      )

      vim.api.nvim_create_user_command(
         "BidiEnableLTR",
         function() M.buf_enable_bidi("ltr") end,
         {}
      )

      -- Manual (RTL)
      vim.api.nvim_create_user_command(
         "BidiConvertRTL",
         function() M.buf_run_fribidi("rtl", true) end,
         {}
      )

      vim.api.nvim_create_user_command(
         "BidiEnablRTL",
         function() M.buf_enable_bidi("rtl") end,
         {}
      )
   end
end

return M
