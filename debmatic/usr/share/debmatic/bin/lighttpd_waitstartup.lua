package.path = '/usr/share/debmatic/bin/?.lua;' .. package.path

local lfs = require("lfs")

if lfs.attributes("/var/status/startupFinished") then
  return 0
end

local req = lighty.r or lighty
local req_header = req.req_header or req.request

local body = "<html><head><title>503 Service unavailable - CCU not fully started</title></head><body><h1>503 Service unavailable - CCU not fully started</h1></body></html>"

local req = lighty.r or lighty
local resp_header = req.resp_header or req.header

if lighty.r then
  lighty.r.resp_body.set({ body })
else
  lighty.content = { body }
end

return 503

