local Utils = require('nvmm.utils')
local uv = vim.uv

local JobQueue = {
  queue = {},
  running = false,
}

function JobQueue:start_next()
  if self.running or #self.queue == 0 then return end
  self.running = true
  local job = table.remove(self.queue, 1)
  self:run_job(job.cmd, job.args, job.callback, job.stdin)
end

function JobQueue:run_job(cmd, args, callback, stdin)
  Utils.message(string.format('Running %s', cmd))
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local stdin_pipe = nil
  local stdout_data, stderr_data = {}, {}

  if stdin then
    stdin_pipe = uv.new_pipe(false)
  end

  local handle = uv.spawn(cmd, {
    args = args,
    stdio = { stdin_pipe, stdout, stderr },
  }, function(code, signal)
    if handle then
      uv.read_stop(stdout)
      uv.read_stop(stderr)
      stdout:close()
      stderr:close()
      if stdin_pipe then stdin_pipe:close() end
      handle:close()
    end

    local result = {
      code = code,
      signal = signal,
      stdout = table.concat(stdout_data),
      stderr = table.concat(stderr_data),
    }

    if code ~= 0 then
      Utils.message(string.format('Job failed: %s (code %d, signal %d)', cmd, code, signal))
      print(result.stderr)
      self.queue = {}
    end

    if callback then callback(result) end
    self.running = false
    self:start_next()
  end)

  if not handle then
    print("Failed to start process: " .. cmd)
    stdout:close()
    stderr:close()
    if stdin_pipe then stdin_pipe:close() end
    self.queue = {}
    return
  end

  uv.read_start(stdout, function(err, data)
    if err then
      table.insert(stderr_data, err)
    elseif data then
      table.insert(stdout_data, data)
    end
  end)

  uv.read_start(stderr, function(err, data)
    if err then
      table.insert(stderr_data, err)
    elseif data then
      table.insert(stderr_data, data)
    end
  end)

  if stdin and stdin_pipe then
    uv.write(stdin_pipe, stdin, function()
      uv.shutdown(stdin_pipe, function()
        stdin_pipe:close()
      end)
    end)
  end
end

function JobQueue:add(cmd, args, callback, stdin)
  table.insert(self.queue, {
    cmd = cmd,
    args = args,
    callback = callback,
    stdin = stdin,
  })
  self:start_next()
end

return JobQueue
