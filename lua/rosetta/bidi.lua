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
      [[echo "]] .. stdin .. [[" | fribidi --nobreak --nopad ]] .. args
   )
end

-- Run buffer through fribidi
-- Returns bidi contents
local function bidi_buf(bufnr)
   return M.fribidi(
      table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
   )
end

--- Enable bidi text in current buffer.
function M.buf_enable_bidi()
   local buf_handle = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(buf_handle)] == nil then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(buf_handle))
      M.active_bufs[tostring(buf_handle)] = true
   end
end

--- Disable bidi text in current buffer.
function M.buf_disable_bidi()
   local buf_handle = vim.api.nvim_win_get_buf(0)
   if M.active_bufs[tostring(buf_handle)] ~= nil then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(buf_handle))
      M.active_bufs[tostring(buf_handle)] = nil
   end
end

--- Run buffer through fribidi
-- This will toggle the text between bidi and no bidi as a static file.
-- @param silent boolean true: no output message
function M.buf_run_fribidi(silent)
   local buf_handle = vim.api.nvim_win_get_buf(0)
   vim.api.nvim_buf_set_lines(0, 0, -1, false, bidi_buf(buf_handle))
   if not silent then msg.info(name, "Ran fribidi on buffer.") end
end

--- Initialize bidi capabilities
function M.init()
   M.config = require("rosetta").config

   M.augroup = vim.api.nvim_create_augroup("BidiGrp", { clear = true })

   -- Autocommand for saving
   if M.config.module.bidi.revert_before_saving then
      vim.api.nvim_create_autocmd({ "BufWritePre", "BufWritePost" }, {
         callback = function(args)
            if M.active_bufs[tostring(buf_handle)] ~= nil then
               M.buf_run_fribidi(true)
            end
         end,
         group = M.augroup,
      })
   end

   -- Autocommands for insert mode.
   if M.config.module.bidi.auto_switch_keyboard then
      vim.api.nvim_create_autocmd("InsertEnter", {
         callback = function(args)
            if M.active_bufs[tostring(buf_handle)] ~= nil then
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
                  if
                     unicode_regex:match_str(sample) ~= nil
                     and M.config.lang[lang].rtl
                  then
                     -- Enable that language if it is RTL
                     kbd.set_keyboard(lang, true)
                     break
                  end
               end
            end
         end,
         group = M.augroup,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
         callback = function(args)
            if M.active_bufs[tostring(buf_handle)] ~= nil then
               kbd.reset_keyboard(true)
            end
         end,
         group = M.augroup,
      })
   end

   -- Create user commands
   if M.config.module.bidi.enabled then
      vim.api.nvim_create_user_command(
         "BidiConvert",
         function() M.buf_run_fribidi(false) end,
         {}
      )

      vim.api.nvim_create_user_command("BidiEnable", M.buf_enable_bidi, {})

      vim.api.nvim_create_user_command("BidiDisable", M.buf_disable_bidi, {})
   end
end

return M
