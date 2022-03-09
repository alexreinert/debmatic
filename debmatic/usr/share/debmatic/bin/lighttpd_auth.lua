package.path = '/usr/share/debmatic/bin/?.lua;' .. package.path

local realm = "CCU"
local host = "127.0.0.1"
local port = 1998

function from_base64 (b64)
  local b64table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
  local bit = require("bitcompat")

  local out = {}
  local i = 1
  local done = false

  local m = #b64 % 4
  if m ~= 0 then
    error "invalid encoding: input is not divisible by 4"
  end

  while i+3 <= #b64 do
    if done then
      error "invalid encoding: trailing characters"
    end

    local a = string.find(b64table, string.sub(b64, i, i)) - 1
    local b = string.find(b64table, string.sub(b64, i + 1, i + 1)) - 1
    local c = string.find(b64table, string.sub(b64, i + 2, i + 2)) - 1
    local d = string.find(b64table, string.sub(b64, i + 3, i + 3)) - 1

    if a == 64 or b == 64 then
      error "invalid encoding: invalid character"
    end

    local x = bit.band(bit.bor(bit.lshift(a, 2), bit.rshift(b, 4)), 0xff)
    local y = bit.band(bit.bor(bit.lshift(b, 4), bit.rshift(c, 2)), 0xff)
    local z = bit.band(bit.bor(bit.lshift(c, 6), d), 0xff)

    if c == 64 then
      assert(d == 64, "invalid encoding: invalid character")
      out[#out + 1] = string.char(x)
      done = true
    elseif d == 64 then
      out[#out + 1] = string.char(x, y)
      done = true
    else
      out[#out + 1] = string.char(x, y, z)
    end
    i = i + 4
  end

  return table.concat(out)
end

function escape_for_rega(t)
  return t:gsub("\\", "\\\\"):gsub(":", "\\:")
end

function check_user_pass(user, pass)
local socket = require("socket")
  udp = assert(socket.udp())

  assert(udp:setpeername(host, port))
  assert(udp:settimeout(1))

  assert(udp:send(user .. ":" .. pass))
  resp = assert(udp:receive())

  udp:close()

  if (resp ~= "1") then
    error("Could not authenticate")
  end
end

function unauthorized()
  local req = lighty.r or lighty
  local resp_header = req.resp_header or req.header
  resp_header["WWW-Authenticate"] = 'Basic realm="' .. realm .. '"'
  resp_header["Content-Type"] = "text/html"

  local body = "<html><head><title>401 Authorization Required</title></head><body><h1>401 Authorization Required</h1></body></html>"

  if lighty.r then
    lighty.r.resp_body.set({ body })
  else
    lighty.content = { body }
  end

  return 401
end

local lfs = require("lfs")

if lfs.attributes("/etc/config/authEnabled") then
  local req = lighty.r or lighty
  local req_header = req.req_header or req.request

  local authorization = req_header["Authorization"]
  if (not authorization) then return unauthorized() end

  local b64auth = string.match(authorization, "^Basic%s+([%w+/=]+)")
  if (not b64auth) then return unauthorized() end

  local auth = from_base64(b64auth)
  if (not auth) then return unauthorized() end

  local user, pass = string.match(auth, "^([^:]+):(.*)$")
  if (not user) then return unauthorized() end

  local isAuth = pcall(check_user_pass, escape_for_rega(user), escape_for_rega(pass))
  if (not isAuth) then return unauthorized() end

  req.req_env["REMOTE_USER"] = user
  req.req_env["AUTH_TYPE"] = "Basic"
end

