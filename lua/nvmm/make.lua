local Csv = require('nvmm.csv')
local Utils = require('nvmm.utils')
local Job = require('nvmm.job')
local Config = require('nvmm.config')
local config = Config.options

local M = {}

local function exit(to, subject, type, n)
  return function(result)
    vim.schedule(function()
      if result.code == 0 then
        if config.options.save_log then
          Utils.write_log(type, subject, to)
        end
        Utils.write_to_quickfix('i', 'Mail "' .. subject .. '" sent successfully to ' .. to, n)
      else
        Utils.write_to_quickfix('e', 'Mail not sent to ' .. to, n)
      end
    end)
  end
end

function M.send(type, subject, content, to, n)
  if to == "nvmm_nil" then
    Utils.write_to_quickfix("e", "This line doesn't contain an email", n)
    if Config.options.options.save_log then
      local message = "LINE " .. n .. " DOESN'T CONTAIN EMAIL"
      Utils.write_log(type, subject, message)
    end
    return
  end

  local attachment = Config.attachment()
  if attachment then
    if n ~= 0 then
      local csv = Config.csv()
      attachment = M.merge(attachment, csv, n)
    end
  else
    attachment = ""
  end

  local text_client = config.options.mail_client.text
  local html_client = config.options.mail_client.html
  local client = (type == "text") and text_client or html_client

  if client == "mailx" or client == "mail" then
    local mailx_args = { "-s", subject }

    if attachment ~= "" then
      table.insert(mailx_args, "-a")
      table.insert(mailx_args, attachment)
    end

    if config.options.mailx_account then
      table.insert(mailx_args, 1, config.options.mailx_account)
      table.insert(mailx_args, 1, "-A")
    end

    table.insert(mailx_args, to)

    Job:add(client, mailx_args, exit(to, subject, type, n), content)

  elseif client == "neomutt" then
    local neomutt_args = {}

    if config.options.neomutt_config then
      table.insert(neomutt_args, "-F")
      table.insert(neomutt_args, config.options.neomutt_config)
    end

    local opts = {
      type == "html" and 'set content_type=text/html' or 'set content_type=text/plain',
      'set copy=no'
    }

    table.insert(neomutt_args, "-e")
    table.insert(neomutt_args, table.concat(opts, "; "))

    table.insert(neomutt_args, "-s")
    table.insert(neomutt_args, subject)

    if attachment ~= "" then
      table.insert(neomutt_args, "-a")
      table.insert(neomutt_args, attachment)
    end

    table.insert(neomutt_args, "--")
    table.insert(neomutt_args, to)

    Job:add("neomutt", neomutt_args, exit(to, subject, type, n), content)

  else
    Utils.message(string.format("Unknown mail client: %s", client), "ERROR")
  end
end

function M.markdown_to_html(md)
  local tmp_md_path = vim.fn.tempname()
  local tmp_md_file = io.open(tmp_md_path, "w")
  if not tmp_md_file then return end

  local line_end = config.options.auto_break_md and "  \n" or "\n"

  for line in io.lines(md) do
    tmp_md_file:write((line:gsub('%$', '_esc_dollar_')) .. line_end)
  end

  tmp_md_file:close()

  local meta = table.concat(config.options.pandoc_metadatas, " --metadata ")

  local cmd = string.format("pandoc %s -s -f markdown -t html5 --metadata %s", tmp_md_path, meta)

  local output = vim.fn.system(cmd)
  if not output or output == "" then return end

  return output:gsub("_esc_dollar_", "%$")
end

function M.merge(input, csv, line)
  local csv_headers = Csv.headers(csv)
  local output = input

  local function replace_variables(text, header, data)
    data = data or nil
    local out
    if data then
      out = text:gsub("%$" .. header, data)
    else
      out = text:gsub(" %$" .. header .. " ", " ")
      out = text:gsub(" %$" .. header, "")
      out = text:gsub("%$" .. header .. " ", "")
      out = text:gsub("%$" .. header, "")
    end
    return out
  end

  for _, header in ipairs(csv_headers) do
    local value = Csv.csv_to_table(csv)[line][header]
    output = replace_variables(output, header, value ~= "nvmm_nil" and value or nil)
  end

  return output
end

return M
