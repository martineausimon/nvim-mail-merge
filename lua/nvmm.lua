local Config = require('nvmm.config')
local Utils  = require('nvmm.utils')
local Ui = require('nvmm.ui')

local M = {}

M.setup = function(opts)
  Config.setup(opts)
end

vim.api.nvim_create_user_command("NVMMConfig",
  function()
    Config.set()
    if Config.csv() then
      local function highlight(headers)
        for _, header in ipairs(headers) do
          vim.fn.matchadd("@variable", "$" .. header)
        end
      end
      highlight(require('nvmm.csv').headers(Config.csv()))
    end
  end,
  { desc = "Config your mail merge, choose .csv file and set subject" }
)

vim.api.nvim_create_user_command("NVMMSendAll",
  function()
    Utils.message(':NVMMSendAll has been removed, use :NVMMSendText or :NVMMSendHtml', 'WARN')
  end,
  { desc = "Deprecated send to all list function" }
)

vim.api.nvim_create_user_command("NVMMAttachment",
  function()
    Config.add_attachment()
  end,
  { desc = "Add attachment to the mail" }
)

vim.api.nvim_create_user_command("NVMMSendText",
  function()
    local Make   = require('nvmm.make')
    local Csv    = require('nvmm.csv')
    local csv = Config.csv()
    if not csv then return end

    local content = io.open(vim.fn.expand('%'), "r"):read("*a")
    local csv_table = Csv.csv_to_table(csv)

    if not csv_table[1]["MAIL"] then
      Utils.message("Can't find MAIL in csv headers", "ERROR")
      return
    else
      for n in ipairs(csv_table) do
        local mail = Make.merge(content, csv, n)
        local subject = Make.merge(Config.subject(), csv, n)
        Make.send("text", subject, mail, csv_table[n]["MAIL"], n)
      end
    end
  end,
  { desc = "Merge current file with .csv file and send it to all list in plain text" }
)

vim.api.nvim_create_user_command("NVMMSendHtml",
  function()
    local Make   = require('nvmm.make')
    local Csv    = require('nvmm.csv')
    local csv = Config.csv()
    if not csv then return end

    local csv_table = Csv.csv_to_table(csv)

    if not csv_table[1]["MAIL"] then
      Utils.message("Can't find MAIL in csv headers", "ERROR")
      return
    else
      for n in ipairs(csv_table) do
        local mail = Make.merge(Make.markdown_to_html(vim.fn.expand('%')), csv, n)
        local subject = Make.merge(Config.subject(), csv, n)
        Make.send("html", subject, mail, csv_table[n]["MAIL"], n)
      end
    end

  end,
  { desc = "Convert .md current file in html, merge with .csv file and send it to all list" }
)

vim.api.nvim_create_user_command("NVMMPreview",
  function()
    local Csv    = require('nvmm.csv')
    local csv = Config.csv()
    if not csv then return end

    local csv_table = Csv.csv_to_table(csv)

    if not csv_table[1]["MAIL"] then
      Utils.message("Can't find MAIL in csv headers", "ERROR")
      return
    end

    local content = io.open(vim.fn.expand('%'), "r"):read("*a")

    Ui.preview_win(content)
  end,
  { desc = "Open a preview in a floating window, merged with the first entry of .csv file" }
)

return M
