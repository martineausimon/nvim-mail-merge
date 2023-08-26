local Utils = require('nvmm.utils')
local csv, subject, attachment

local M = {}

function M.defaults()
  local defaults = {
    mappings = {
      attachment = "<leader>a",
      config = "<leader>c",
      preview = "<leader>p",
      send_all = "<leader>sa",
      send_text = "<leader>st",
      send_html = "<leader>sh",
    },
    options = {
      mail_client = {
        text = "neomutt",
        html = "neomutt"
      },
      auto_break_md = true,
      neomutt_config = "$HOME/.neomuttrc",
      mailx_account = nil,
      save_log = true,
      log_file = "./nvmm.log",
      date_format = "%Y-%m-%d"
    }
  }
  return defaults
end

function M.set()
  vim.api.nvim_command("silent! write")
  vim.ui.input(
    { prompt = "[NVMM] .csv file ? ", completion = "file" },
    function(input) csv = input or nil end
  )

  local file_exists = io.open(csv, "r")
  local mime_type_csv = io.popen("file --mime-type -b " .. csv):read("*a") == "text/csv\n"

  if csv == "" then
    Utils.message('No csv file entered.', 'ERROR')
    return
  elseif not file_exists then
    Utils.message('The file ' .. csv .. ' does not exist.', 'ERROR')
    return
  elseif not mime_type_csv then
    Utils.message('The file ' .. csv .. ' is not a valid csv file.', 'ERROR')
    return
  end

  io.close(file_exists)

  vim.ui.input(
    { prompt = "[NVMM] Subject ? ", },
    function(input) subject = input or " " end
  )
end

function M.csv()
  if not csv then
    Utils.message('Run config first', 'WARN')
  else
    local csv_file = io.open(csv, "r")
    if not csv_file then
      return nil
    end

    local csv_string = csv_file:read("*all")
    csv_file:close()

    return csv_string, csv
  end
end

function M.subject()
  if not subject then
    Utils.message('Run config first', 'WARN')
  else
    return subject
  end
end

function M.add_attachment()
  vim.ui.input(
    { prompt = "[NVMM] attachment ? ", completion = "file" },
    function(input) attachment = input or nil end
  )
end

function M.attachment()
  return attachment or nil
end

M.options = {}

function M.setup(options)
  options = options or {}
  M.options = vim.tbl_deep_extend("force", {}, M.defaults(), options)
  vim.keymap.set("n", M.options.mappings.config,     "<cmd>NVMMConfig<cr>",     {})
  vim.keymap.set("n", M.options.mappings.preview,    "<cmd>NVMMPreview<cr>",    {})
  vim.keymap.set("n", M.options.mappings.attachment, "<cmd>NVMMAttachment<cr>", {})
  vim.keymap.set("n", M.options.mappings.send_text,  "<cmd>NVMMSendText<cr>",   {})
  vim.keymap.set("n", M.options.mappings.send_html,  "<cmd>NVMMSendHtml<cr>",   {})
end

return M
