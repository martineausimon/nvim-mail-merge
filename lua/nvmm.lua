local M = {}

-- Config

local default = {
  mappings = {
    config = "<leader>c",
    preview = "<leader>p",
    send_all = "<leader>sa"
  },
  options = {
    tmp_folder = "/tmp/nvmm/", 
    neomutt_config = "$HOME/.neomuttrc"
  }
}

M.setup = function(opts)
  opts = opts or {}
  nvmm_options = vim.tbl_deep_extend('keep', opts, nvmm_options or default)
end

M.setup()

-- Variables, mappings & commandes

local line_count   = 2
local md     = vim.fn.expand("%")
local csv    = ""
local object = ""
local ucmd   = vim.api.nvim_create_user_command
local kmap   = vim.api.nvim_buf_set_keymap
local nrm    = { noremap = true }

ucmd("NVMMConfig", function() M.set() end, {})
kmap(0, 'n', nvmm_options.mappings.config, ":NVMMConfig<cr>", nrm)
ucmd("NVMMPreview", function() M.preview() end, {})
kmap(0, 'n', nvmm_options.mappings.preview, ":NVMMPreview<cr>", nrm)
ucmd("NVMMSendAll", function() 
  vim.fn.mkdir(nvmm_options.options.tmp_folder, "p")
  M.sendAll() 
end, {})
kmap(0, 'n', nvmm_options.mappings.send_all, ":NVMMSendAll<cr>", nrm)

-- Lire les valeurs d'une ligne et d'une colonne d'un fichier csv

function M.readValues(filename, row, col)
  local file = io.open(filename, "r")
  for i = 1, row do
    local line = file:read()
    if i == row then
      local values = {}
      if line == nil then do return end end
      for value in line:gmatch("([^,]+)") do
        table.insert(values, value)
      end
      file:close()
      return values[col]
    end
  end
  return nil
end

-- Lire une ligne du .csv (nom, ligne)

function M.readLine(filename,l)
    local file = io.open(filename, "r")
    local line_count = 0
    for line in file:lines() do
        line_count = line_count + 1
        if line_count == l then
            return line
        end
    end
    file:close()
end

-- Connaitre la position de MAIL dans les headers

function M.getMailPos(h)
  local m = h:match("(.*MAIL)")
  local _,m = m:gsub(",","")
  m = m + 1
  return m
end

-- Stocker les titres dans une table + Highlightings

function M.storeHeaders(h)
  local headers_count = 0
  local headers = {}
  for header in string.gmatch(h, "([^,]+)") do
    headers_count = headers_count + 1
    headers[headers_count] = header
    vim.fn.matchadd("SpecialChar", "$" .. header) 
  end
  return headers
end

-- Stocker le fichier md dans une variable :

function M.storeMD(filename)
  local file = io.open(filename, "r")
  local file_content = ""
  for line in file:lines() do
    local line_content = ""
    for word in string.gmatch(line,"([^%s]+)") do
      line_content = line_content .. word .. " "
    end
    file_content = file_content .. line_content .. " \n"
  end
  file:close()
  return file_content
end

-- Modifie mdStored avec les valeurs de header_table :

function M.cmpHeadersEntries(l)
  local file_content = M.storeMD(md)
  mail_object = object
  for n=1,#headers_table do
    file_content = file_content:gsub("%$" .. headers_table[n], M.readValues(csv,l,n))
    mail_object = mail_object:gsub("%$" .. headers_table[n], M.readValues(csv,l,n))
  end
  return file_content
end

function M.preview()
  if not header_table then 
    print("[NVMM] Run config first with " .. 
      nvmm_options.mappings.config)
    do return end
  end
  local file_content = M.storeMD(md)
  mail_object = object
  for n=1,#headers_table do
    file_content = file_content:gsub("%$" .. headers_table[n], M.readValues(csv,2,n))
    mail_object = mail_object:gsub("%$" .. headers_table[n], M.readValues(csv,2,n))
  end
  print("Object: " .. mail_object .. "\n")
  print(file_content)
end
-- Ecrire un fichier MD avec les valeurs contenues dans une ligne :

function M.sendAll()
  if not headers_table then
    print("[NVMM] Run config first with " .. 
      nvmm_options.mappings.config)
    do return end
  end
  email = M.readValues(csv,line_count,M.getMailPos(M.readLine(csv,1))) or nil
  if email == nil then 
    print("[NVMM] No more mail to send.")
    do return end
  end
  local file = io.open(nvmm_options.options.tmp_folder .. email .. ".md", "w")
  file:write(M.cmpHeadersEntries(line_count))
  file:close()
  local c = "pandoc -s -f markdown --metadata 'title: ' " ..
      "--metadata 'mainfont: sans-serif' " .. 
      nvmm_options.options.tmp_folder .. email ..
      ".md -o " .. nvmm_options.options.tmp_folder .. email .. ".html"
  -- TODO : write correct error format for qf
  local e = " "
  local ctrl = "convert"
  M.async(c,e,ctrl)
end

-- Envoi complet :

function M.send()
  local c = [[neomutt ]] ..
  [[-e "set content_type=text/html" -e "set copy=no" ]].. 
  [[-F ]] .. nvmm_options.options.neomutt_config .. [[ ]] ..
  [[-s ]] .. [["]] .. mail_object .. [[" ]] ..
  [[-- "mailto:]] .. email .. [[" < ]] .. 
  nvmm_options.options.tmp_folder .. email .. [[.html]]
  -- TODO : write correct error format for qf
  local e = " " 
  local ctrl = "send"
  M.async(c,e,ctrl)
  vim.fn.execute("!rm -f " .. nvmm_options.options.tmp_folder .. email .. [[.*]])
end

-- Function async

function M.async(c,e,ctrl)
  ctrl = ctrl or nil
  local lines = {""}
  local cmd = vim.fn.expandcmd(c)
  local function on_event(job_id, data, event)
    if event == "stdout" or event == "stderr" then
      if data then
        vim.list_extend(lines, data)
      end
    end

    if event == "exit" then
      vim.fn.setqflist({}, " ", {
        title = cmd,
        lines = lines,
        efm = e,
      })
      vim.api.nvim_exec_autocmds("QuickFixCmdPost", {})
      if ctrl == "convert" then
        print('[NVMM] Sending to ' .. email)
        M.send()
      elseif ctrl == "send" then
        line_count = line_count + 1
        M.sendAll(line_count)
      end
    end
  end
  local job_id =
    vim.fn.jobstart(
      cmd,
      {
        on_stderr = on_event,
        on_stdout = on_event,
        on_exit = on_event,
        stdout_buffered = true,
        stderr_buffered = true,
      }
    )
end

-- Définir le fichier csv et l'objet du mail

function M.set()
  vim.ui.input({
    prompt = "[NVMM] .csv file ? ",
    completion = "file"
  }, 
    function(input)
      csv = input or nil
    end)
  if not csv then 
    print('[NVMM] No csv file entered.')
    do return end end
  headers_table = M.storeHeaders(M.readLine(csv,1))
  vim.ui.input({
    prompt = "[NVMM] Object ? ",
  }, 
    function(input)
      object = input or " "
    end)
end

return M
