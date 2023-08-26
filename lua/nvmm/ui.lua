local M = {}

function M.preview_win(content)
  local Config = require('nvmm.config')
  local Csv    = require('nvmm.csv')
  local Make   = require('nvmm.make')

  local csv = Config.csv()
  local csv_table = Csv.csv_to_table(csv)

  local win_width = vim.api.nvim_win_get_width(0)
  local width = math.floor(win_width * 0.8)
  local col = math.floor((win_width / 2) - (width / 2))

  local win_height = vim.api.nvim_win_get_height(0)
  local height = math.floor(win_height * 0.8)
  local row = math.floor((win_height / 2) - (height / 2))

  local separator = string.rep("─", width)

  local preview_table = {
    separator,
    "TO:         " .. csv_table[1]["MAIL"],
    "SUBJECT:    " .. (Config.subject() ~= "" and Make.merge(Config.subject(), csv, 1) or "<none>"),
    "ATTACHMENT: " .. (Config.attachment() and Make.merge(Config.attachment(), csv, 1) or "<none>"),
    separator,
    "",
    Make.merge(content, csv, 1)
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    row = row,
    col = col - 1,
    width = width,
    height = height,
    border = 'single',
    focusable = true
  }

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, opts)

  preview_lines = table.concat(preview_table, "\n")

  local lines = vim.split(preview_lines, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.api.nvim_set_current_win(win)

  vim.fn.matchadd("htmlH2", "TO:")
  vim.fn.matchadd("htmlH2", "SUBJECT:")
  vim.fn.matchadd("htmlH2", "ATTACHMENT:")
  vim.api.nvim_buf_add_highlight(buf, -1, "LineNr", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "LineNr", 4, 0, -1)

  vim.keymap.set('n', '<esc>', "<cmd>q<cr>", { silent = true, buffer = buf })

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
end

return M
