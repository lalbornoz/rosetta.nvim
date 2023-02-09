----------
-- Bidirectional (bidi) handling in Rosetta.
-- @module bidi

local M = {}

local name = "Bidi"
local kbd = require("rosetta.keyboard")
local msg = require("rosetta.message")
local util = require("rosetta.util")
local c = require("rosetta.config").options

--- A list of the IDs of buffers with bidi enabled.
-- Key: ID of the Buffer
-- Value: Boolean. If true, buffer is RTL.
M.active_bufs = {}

local active_autocmds = {} -- List of autocommands currently active

--- Activate revins depending on the language
-- @string lang The language to be used.
function M.revins(lang)
   if c.lang[lang].rtl then
      vim.o.revins = true

      if c.bidi.intuitive_delete then
         vim.keymap.set("i", "<BS>", "<Del>", { buffer = true })
         vim.keymap.set("i", "<Del>", "<BS>", { buffer = true })
      end
   else
      vim.o.revins = false

      if c.bidi.intuitive_delete then
         vim.keymap.set("i", "<BS>", "<BS>", { buffer = true })
         vim.keymap.set("i", "<Del>", "<Del>", { buffer = true })
      end
   end
end

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

      -- Switch to revins if keyboard language is RTL
      -- Auto-keyboard switch handles this when its enabled.
      local autocmd_id = vim.api.nvim_create_autocmd("InsertEnter", {
         callback = function(args)
            if
               not (c.keyboard.enabled and kbd.auto)
               and M.active_bufs[tostring(bufnr)] ~= nil
            then
               local lang = string.match(vim.bo.keymap, "^%w+") or "english"
               M.revins(lang)
            end
         end,
         group = M.augroup,
      })

      active_autocmds["insert_auto_switch"] = autocmd_id
   else
      msg.error(name, "Bidi Mode already enabled.")
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

      -- Remove revins autocmd
      if active_autocmds["insert_auto_switch"] ~= nil then
         vim.api.nvim_del_autocmd(active_autocmds["insert_auto_switch"])
         active_autocmds["insert_auto_switch"] = nil
      end

      -- Configure reverse insert
      vim.o.revins = false
   else
      msg.error(name, "Bidi Mode already disabled.")
   end
end

--- Initialize bidi capabilities
function M.init()
   M.augroup = vim.api.nvim_create_augroup("RosettaBidi", { clear = true })

   local default_rtl = c.lang[c.lang.default].rtl

   -- Autocommand for saving
   if c.bidi.revert_before_saving then
      vim.api.nvim_create_autocmd({ "BufWritePre", "BufWritePost" }, {
         callback = function(args)
            if M.active_bufs[tostring(args.buf)] ~= nil then
               local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
               lines = M.fribidi(lines, M.active_bufs[tostring(args.buf)])
               vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
            end
         end,
         group = M.augroup,
      })
   end

   -- Autocommand for pasting
   vim.api.nvim_create_autocmd("TextYankPost", {
      pattern = "*",
      callback = function(args)
         if vim.v.event.regname == c.bidi.register then
            local rtl = M.active_bufs[tostring(bufnr)] or default_rtl
            local content = M.fribidi(vim.v.event.regcontents, rtl)[1]
            vim.fn.setreg(c.bidi.register, content)
         end
      end,
      group = M.augroup,
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
