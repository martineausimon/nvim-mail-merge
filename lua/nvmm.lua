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

local function direct_send(type, mail, recipients)
  local Make   = require('nvmm.make')

  local subject

  vim.ui.input(
    { prompt = "[NVMM] Subject ? ", },
    function(input) subject = input or " " end
  )

  for _, recipient in ipairs(recipients) do
    Make.send(type, subject, mail, recipient, 0)
  end
end

vim.api.nvim_create_user_command("NVMMSendText",
  function(args)
    vim.fn.execute('write')
    local Make   = require('nvmm.make')
    local Csv    = require('nvmm.csv')
    local content = io.open(vim.fn.expand('%'), "r"):read("*a")

    local mails = {}

    for _, arg in ipairs(args.fargs) do
      local split_mails = vim.fn.split(arg, ',')
      for _, split_mail in ipairs(split_mails) do
        table.insert(mails, split_mail)
      end
    end

    if mails and #mails > 0 then
      direct_send("text", content, mails)
      return
    end

    local csv = Config.csv()
    if not csv then return end

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
  {
    nargs = "*",
    desc = "Sends an email in plain text format. Merges the content of the current file with your .csv file and sends it to all addresses in the list. If provided, sends the buffer's content to a recipient email."
  }
)

vim.api.nvim_create_user_command("NVMMSendHtml",
  function(args)
    vim.fn.execute('write')
    local Make   = require('nvmm.make')
    local Csv    = require('nvmm.csv')
    local content = Make.markdown_to_html(vim.fn.expand('%'))

    local mails = {}

    for _, arg in ipairs(args.fargs) do
      local split_mails = vim.fn.split(arg, ',')
      for _, split_mail in ipairs(split_mails) do
        table.insert(mails, split_mail)
      end
    end

    if mails and #mails > 0 then
      direct_send("html", content, mails)
      return
    end

    local csv = Config.csv()
    if not csv then return end

    local csv_table = Csv.csv_to_table(csv)

    if not csv_table[1]["MAIL"] then
      Utils.message("Can't find MAIL in csv headers", "ERROR")
      return
    else
      for n in ipairs(csv_table) do
        local mail = Make.merge(content, csv, n)
        local subject = Make.merge(Config.subject(), csv, n)
        Make.send("html", subject, mail, csv_table[n]["MAIL"], n)
      end
    end

  end,
  {
    nargs = "*",
    desc = "Convert .md current file in html, merge with .csv file and send it to all list or send to recipients if provided"
  }
)

vim.api.nvim_create_user_command("NVMMPreview",
  function()
    vim.fn.execute('write')
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
