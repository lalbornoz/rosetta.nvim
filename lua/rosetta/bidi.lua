local M = {}

local name = "Bidi"
local kbd = require("rosetta.keyboard")
local msg = require("rosetta.message")

-- A list of the IDs of buffers with bidi enabled.
M.active_bufs = {}

--- Send string to fribidi
-- @param stdin string
-- @param args string
function M.fribidi(stdin, args)
   local args = args or ""
   return vim.fn.systemlist(
      [[echo ']] .. stdin .. [[' | fribidi --nobreak --nopad ]] .. args
   )
end

-- Run buffer through fribidi
-- Returns bidi contents
local function bidi_buf(bufnr, dir)
   local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
   lines = vim.tbl_map(function(line) return line:gsub([[']], [['\'']]) end, lines)
   return M.fribidi(table.concat(lines, "\n"), "--" .. dir)
end

--- Enable bidi text in current buffer.
function M.buf_enable_bidi(dir)
   local buf_handle = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(buf_handle)] == nil then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(dir))
      M.active_bufs[tostring(buf_handle)] = true
   end
end

--- Disable bidi text in current buffer.
function M.buf_disable_bidi(dir)
   local buf_handle = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(buf_handle)] ~= nil then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(dir))
      M.active_bufs[tostring(buf_handle)] = nil
   end
end

--- Run buffer through fribidi
-- This will toggle the text between bidi and no bidi as a static file.
function M.buf_run_fribidi(dir, silent)
   local buf_handle = vim.api.nvim_win_get_buf(0)
   vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(buf_handle, dir))
   if not silent then msg.info(name, "Ran fribidi on buffer.") end
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
               M.buf_run_fribidi(true)
            end
         end,
         group = M.augroup,
      })
   end

   -- Create user commands
   if M.config.bidi.enabled then
      -- Find default bidi direction
      local default_dir = M.config.lang[M.config.options.default].rtl and "rtl" or "ltr"

      -- Default
      vim.api.nvim_create_user_command(
         "BidiConvert",
         function()
            M.buf_run_fribidi(default_dir, true)
         end,
         {}
      )

      vim.api.nvim_create_user_command("BidiEnable", function()
         M.buf_enable_bidi(default_dir)
      end, {})

      vim.api.nvim_create_user_command("BidiDisable", function()
         M.buf_disable_bidi(default_dir)
      end, {})

      -- Manual (LTR)
      vim.api.nvim_create_user_command(
         "BidiConvertLTR",
         function() M.buf_run_fribidi("ltr", true) end,
         {}
      )

      vim.api.nvim_create_user_command("BidiEnableLTR", function()
         M.buf_enable_bidi("ltr")
      end, {})

      vim.api.nvim_create_user_command("BidiDisableLTR", function()
         M.buf_disable_bidi("ltr")
      end, {})

      -- Manual (RTL)
      vim.api.nvim_create_user_command(
         "BidiConvertRTL",
         function() M.buf_run_fribidi("rtl", true) end,
         {}
      )

      vim.api.nvim_create_user_command("BidiEnablRTL", function()
         M.buf_enable_bidi("rtl")
      end, {})

      vim.api.nvim_create_user_command("BidiDisablRTL", function()
         M.buf_disable_bidi("rtl")
      end, {})
   end
end

return M