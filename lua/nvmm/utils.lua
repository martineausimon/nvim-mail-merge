local M = {}

function M.message(str, level)
  level = level or "INFO"
  vim.notify("[NVMM] " .. str, vim.log.levels[level], {})
end

function M.shellescape(content)
  local chars = {
    ['"'] = '\\" ',
    ["'"] = "\\'",
  }

  for i, j in pairs(chars) do
    content = content:gsub(i, j)
  end

  return content
end

function M.write_log(type, subject, message)
  local config = require('nvmm.config').options

  local file, err = io.open(config.options.log_file, "a")
  if not file then
    M.message("Error opening log file: " .. err, "ERROR")
    return
  end

  local date = os.date(config.options.date_format)
  type = (type == "text") and "" or ""

  local log = string.format("%s [%s] %s | %s", date, type, subject, message)
  file:write(log .. "\n")
  file:close()
end

local qf_lines = {}

-- A AMÉLIORER : PLUTÔT QUE #QF_LINES + 1, UTILISER LA LIGNE DU FICHIER CSV

function M.write_to_quickfix(type, message, n)
  local file
  if n == 0 then
    file = vim.fn.expand('%')
  else
    local _, csv = require('nvmm.config').csv()
    file = csv
  end
  table.insert(qf_lines, file .. ":" .. n .. ":" .. type .. ":" .. message)
  vim.fn.setqflist({}, " ", {
    title = "nvim-mail-merge",
    lines = qf_lines,
    efm = "%f:%l:%t:%m",
  })
  vim.api.nvim_exec_autocmds("QuickFixCmdPost", {})
end

return M
