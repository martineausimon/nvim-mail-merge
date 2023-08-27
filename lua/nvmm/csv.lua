local Utils = require('nvmm.utils')

local M = {}

function M.split(str, d)
  str = str:gsub("^" .. d, "nvmm_nil" .. d)
  str = str:gsub(d .. "$", d .. "nvmm_nil")
  local _,m = str:gsub(d,"")
  for _ = 1, m do
    str = str:gsub(d .. d, d .. "nvmm_nil" .. d)
  end
  local result = {}
  local pattern = string.format("([^%s]+)", d)
  for token in string.gmatch(str, pattern) do
    table.insert(result, token)
  end
  return result
end

function M.csv_to_table(csv)
  local lines = {}
  local headers = {}

  for line in csv:gmatch("[^\r\n]+") do
    local row = M.split(line, ",")

    if #headers == 0 then
      headers = row
    else
      local rowData = {}
      for i, value in ipairs(row) do
        rowData[headers[i]] = value
      end
      table.insert(lines, rowData)
    end
  end

  return lines
end

function M.headers(csv)
  local headers = {}
  local firstLine = csv:match("[^\r\n]+")
  local row = M.split(firstLine, ",")

  for _, header in ipairs(row) do
      table.insert(headers, header)
  end

  return headers
end

function M.content(file_path)
  local file = io.open(file_path, "r")
  if not file then
    Utils.message('Failed to open file: ' .. file_path, 'WARN')
  else
    local content = file:read("*all")
    file:close()

    return content
  end
end

return M
