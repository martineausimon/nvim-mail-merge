local M = {}

-- Config

local default = {
  mappings = {
    attachment = "<leader>a",
    config = "<leader>c",
    preview = "<leader>p",
    send_all = "<leader>sa"
  },
  options = {
    tmp_folder = "/tmp/nvmm/", 
    neomutt_config = "$HOME/.neomuttrc",
    save_log = true,
    log_file = "./nvmm.log",
    date_format = "%Y-%m-%d"
  }
}

M.setup = function(opts)
  opts = opts or {}
  nvmm_options = vim.tbl_deep_extend('keep', opts, nvmm_options or default)
end

M.setup()

-- Variables, mappings & commands

local line_count   = 2
local md     = vim.fn.expand("%")
local csv    = ""
local subject = ""
local ucmd   = vim.api.nvim_create_user_command
local kmap   = vim.api.nvim_buf_set_keymap
local nrm    = { noremap = true }

ucmd("NVMMConfig", function() M.set() end, {})
kmap(0, 'n', nvmm_options.mappings.config, ":NVMMConfig<cr>", nrm)

ucmd("NVMMPreview", function() 
  if not headers_table then 
    print("[NVMM] Run config first with " .. 
      nvmm_options.mappings.config)
    do return end
  else
    -- Floating window for preview
    local screen_width, screen_height = vim.api.nvim_get_option("columns"), vim.api.nvim_get_option("lines")
    local demi_screen_width = math.floor(screen_width / 2)
    local demi_screen_height = math.floor(screen_height / 2)
    local w_width = math.floor(screen_width / 1.2)
    local w_height = math.floor(screen_height / 1.2)
    local x = math.floor(demi_screen_width - w_width / 2)
    local y = math.floor(demi_screen_height - w_height / 2)
    local opts = {
      relative = "win",
      width = w_width,
      height = w_height,
      col = x,
      row = y,
      style = "minimal",
      border = "single"
    }
    local preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(preview_buf, 'filetype', 'markdown')
    local lines = M.preview()
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, true, lines) 
    local preview_win = vim.api.nvim_open_win(preview_buf, true, opts)
    -- Highlights in preview window
    vim.fn.matchadd("htmlH2", "TO:")
    vim.fn.matchadd("htmlH2", "SUBJECT:")
    vim.fn.matchadd("htmlH2", "ATTACHMENT:")
  end
end, {})
kmap(0, 'n', nvmm_options.mappings.preview, ":NVMMPreview<cr>", nrm)

ucmd("NVMMSendAll", function() 
  if not headers_table then
    print("[NVMM] Run config first with " .. 
      nvmm_options.mappings.config)
    do return end
  end
  -- create a tmp folder where md files are stored, then deleted
  vim.fn.mkdir(nvmm_options.options.tmp_folder, "p")
  -- create floating window to follow the mails sent
  sended = vim.api.nvim_create_buf(false, true)
  local screen_width, screen_height = vim.api.nvim_get_option("columns"), vim.api.nvim_get_option("lines")
  local demi_screen_width = math.floor(screen_width / 2)
  local demi_screen_height = math.floor(screen_height / 2)
  local w_width = math.floor(screen_width / 2)
  local w_height = math.floor(screen_height / 2)
  local x = math.floor(demi_screen_width - w_width / 2)
  local y = math.floor(demi_screen_height - w_height / 2)
  local opts = {
    relative = "win",
    width = w_width,
    height = w_height,
    col = x,
    row = y,
    style = "minimal",
    border = "single"
  }
  vim.api.nvim_open_win(sended, true, opts)
  vim.fn.matchadd("htmlH2", "SENT TO:")
  m_sent = 1
  vim.api.nvim_buf_set_lines(sended, 0, 0, false, { "SENT TO:" })
  M.sendAll() 
end, {})
kmap(0, 'n', nvmm_options.mappings.send_all, ":NVMMSendAll<cr>", nrm)

ucmd("NVMMAttachment", function()
    vim.ui.input({
    prompt = "[NVMM] Attachment ? ",
    completion = "file"
  }, 
    function(input)
      attachment = input or nil
    end)
end, {})
kmap(0, 'n', nvmm_options.mappings.attachment, ":NVMMAttachment<cr>", nrm)

-- Read the values of a line and a column of a csv file

function M.readValues(filename, row, col)
    local file = io.open(filename, "r")
    for i = 1, row do
        local line = file:read()
        if i == row then
            local values = {}
            if line == nil then do return end end
            local _,m = line:gsub(",","")
            for i = 1, m do
              -- If empty data in csv
              line = line:gsub("^,", "nvmm_nil,")
              line = line:gsub(",,", ",nvmm_nil,")
            end
            for value in line:gmatch("([^,]+)") do
              table.insert(values, value)
            end
            file:close()
            return values[col]
        end
    end
    return nil
end

-- Read a line of .csv

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

-- Know the position of MAIL in the headers

function M.getMailPos(h)
  local m = h:match("(.*MAIL)")
  local _,m = m:gsub(",","")
  m = m + 1
  return m
end

-- Store titles in a table + Highlightings

function M.storeHeaders(h)
  local headers_count = 0
  local headers = {}
  for header in string.gmatch(h, "([^,]+)") do
    headers_count = headers_count + 1
    headers[headers_count] = header
    vim.fn.matchadd("Identifier", "$" .. header) 
  end
  return headers
end

-- Store the md file in a variable :

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

-- Modify mdStored with the values of header_table :

function M.cmpHeadersEntries(l)
  local file_content = M.storeMD(md)
  mail_subject = subject
  for n=1,#headers_table do
    local sub = M.readValues(csv,l,n)
      if sub ~= "nvmm_nil" then
      file_content = file_content:gsub("%$" .. headers_table[n], sub)
      mail_subject = mail_subject:gsub("%$" .. headers_table[n], sub)
      if attachment then
        pj = attachment:gsub("%$" .. headers_table[n], sub)
      end
    else
      file_content = file_content:gsub(" %$" .. headers_table[n], "")
      mail_subject = mail_subject:gsub(" %$" .. headers_table[n], "")
      if attachment then
        pj = attachment:gsub(" %$" .. headers_table[n], "")
      end
    end
  end
  return file_content
end

-- Preview the mail

function M.preview()
  local lines = {}
  local file_content = M.storeMD(md)
  local mail_subject = subject
  local att = attachment or "<empty>"
  local email = M.readValues(csv,2,M.getMailPos(M.readLine(csv,1)))
  for n=1,#headers_table do
    local sub = M.readValues(csv,2,n)
    if sub ~= "nvmm_nil" then
      file_content = file_content:gsub("%$" .. headers_table[n], sub)
      mail_subject = mail_subject:gsub("%$" .. headers_table[n], sub)
      att = att:gsub("%$" .. headers_table[n], sub)
    else
      file_content = file_content:gsub(" %$" .. headers_table[n], "")
      mail_subject = mail_subject:gsub(" %$" .. headers_table[n], "")
      att = att:gsub(" %$" .. headers_table[n], "")
    end
  end
  table.insert(lines, "-------------------")
  table.insert(lines, "TO:         " .. email)
  table.insert(lines, "SUBJECT:    " .. mail_subject)
  table.insert(lines, "ATTACHMENT: " .. att)
  table.insert(lines, "-------------------")
  table.insert(lines, " ")
  for line in string.gmatch(file_content, "[^\n]+") do
    table.insert(lines, line)
  end
  return lines
end

-- Write a MD file with the values contained in a line and convert in html

function M.sendAll()
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

-- Full send :

function M.send()
  if pj then
    att = [[-a ]] .. pj .. [[ ]]
  else 
    att = ""
  end
  local c = [[neomutt ]] ..
  [[-e "set content_type=text/html" -e "set copy=no" ]].. 
  [[-F ]] .. nvmm_options.options.neomutt_config .. [[ ]] ..
  [[-s ]] .. [["]] .. mail_subject .. [[" ]] .. att ..
  [[-- "mailto:]] .. email .. [[" < ]] .. 
  nvmm_options.options.tmp_folder .. email .. [[.html]]
  -- TODO : write correct error format for qf
  local e = " " 
  local ctrl = "send"
  if nvmm_options.options.save_log then
    local current_date = os.date(nvmm_options.options.date_format)
    local log = current_date .. 
    " | " .. mail_subject .. 
    " | " .. email
    -- Print new line in floating window
    vim.api.nvim_buf_set_lines(sended, -1, -1, false, { m_sent .. " | " .. email })
    m_sent = m_sent + 1
    M.writeLog(log)
  end
  M.async(c,e,ctrl)
  vim.fn.execute("!rm -f " .. nvmm_options.options.tmp_folder .. email .. [[.*]])
end

-- Save infos in a log file

function M.writeLog(line)
  local file, err = io.open(nvmm_options.options.log_file, "a")
  if not file then
    print("[NVMM] Error opening log file:", err)
    do return end
  else
    file:write(line .. "\n")
    file:close()
  end
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

-- Define the csv file and the mail object

function M.set()
  vim.api.nvim_command("silent! write")
  vim.ui.input({
    prompt = "[NVMM] .csv file ? ",
    completion = "file"
  }, 
    function(input)
      csv = input or nil
    end)
  local file = csv
  if not file then 
    vim.cmd[[redraw]]
    print('[NVMM] No csv file entered.')
    return
  end
  local test_file = io.open(csv, "r")
  if not test_file then
    vim.cmd[[redraw]]
    print("[NVMM] The file " .. csv .. " does not exist.")
    return
  end
  io.close(test_file)

  headers_table = M.storeHeaders(M.readLine(csv,1))
  vim.ui.input({
    prompt = "[NVMM] Subject ? ",
  }, 
    function(input)
      subject = input or " "
    end)
end

return M
