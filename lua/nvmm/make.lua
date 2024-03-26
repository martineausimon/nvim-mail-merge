Csv = require('nvmm.csv')
Utils = require('nvmm.utils')
Config = require('nvmm.config')
config = Config.options
local mail_client = config.options.mail_client

local M = {}

local function exit(to, subject, tmpfile, type, n)
  return function(_, code)
    if code == 0 then
      if config.options.save_log then
        Utils.write_log(type, subject, to)
      end
      Utils.write_to_quickfix('i', 'Mail "' .. subject .. '" sent successfully to ' .. to, n)
    else
      Utils.write_to_quickfix('e', 'Mail not sent.', n)
    end
    os.remove(tmpfile)
  end
end

local function send_cmd(mode)
  local args = {}
  if mode == "text" then
    if mail_client.text == "neomutt" then
      if config.options.neomutt_config then
        table.insert(args, " -F " .. config.options.neomutt_config)
      end
      local options = {
        'set content_type=text/plain',
        'set send_charset=utf-8',
        'set copy=no'
      }
      local opts = table.concat(options, '" -e "')
      table.insert(args, ' -e "' .. opts ..'"')
    elseif mail_client.text == "mail" or mail_client.text == "mailx" then
      if config.options.mailx_account then
        table.insert(args, " -A " .. config.options.mailx_account)
      end
    elseif not mail_client.text then
      Utils.message('No email client specified for text mails', 'WARN')
      return
    else
      Utils.message(('Unknow mail client for text mails (%s)'):format(mail_client.text), 'WARN')
      return
    end
  elseif mode == "html" then
    if mail_client.html == "neomutt" then
      if config.options.neomutt_config then
        table.insert(args, " -F " .. config.options.neomutt_config)
      end
      local options = {
        'set content_type=text/html',
        'set copy=no'
      }
      local opts = table.concat(options, '" -e "')
      table.insert(args, '-e "' .. opts ..'"')
    end
  end
  local string_args = table.concat(args, ' ')
  local cmd = string.format('%s%s', mail_client[mode], string_args)
  return cmd
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

  local tmpfile = vim.fn.tempname()
  local file = io.open(tmpfile, "w")
  if not file then return end

  file:write(content)
  file:close()

  local cmd = send_cmd(type)

  local attachment = Config.attachment()

  if attachment then
    if n ~= 0 then
      local csv = Config.csv()
      attachment = M.merge(attachment, csv, n)
    end
    attachment = ' -a ' .. attachment
  else
    attachment = ""
  end

  local text_client = Config.options.options.mail_client.text
  local make
  if type == "text" and (text_client == "mailx" or text_client == "mail") then
    make = string.format([[cat %s | %s -s %q%s %s]], tmpfile, cmd, subject, attachment, to)
  else
    make = string.format([[cat %s | %s -s %q %s%s]], tmpfile, cmd, subject, to, attachment)
  end

  local function send_with_delay()
    vim.fn.jobstart(make, {
      on_exit = exit(to, subject, tmpfile, type, n)
    })
  end

  vim.defer_fn(send_with_delay, 4000)
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
