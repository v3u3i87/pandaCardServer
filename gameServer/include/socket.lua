local bit = require "bit"

local http_ver = ngx.req.http_version
local req_sock = ngx.req.socket
local ngx_header = ngx.header
local req_headers = ngx.req.get_headers
local str_lower = string.lower
local char = string.char
local str_find = string.find
local sha1_bin = ngx.sha1_bin
local base64 = ngx.encode_base64
local ngx = ngx
local read_body = ngx.req.read_body

local byte = string.byte
local char = string.char
local sub = string.sub
local str_char = string.char

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local lshift = bit.lshift
local rshift = bit.rshift
local tohex = bit.tohex

local concat = table.concat
local rand = math.random

local type = type
local setmetatable = setmetatable

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local types = {
    [0x0] = "continuation",
    [0x1] = "text",
    [0x2] = "binary",
    [0x8] = "close",
    [0x9] = "ping",
    [0xa] = "pong",
}

local _M = {}
_M._VERSION = '0.01'

local mt = { __index = _M }

function _M.new(self,opts)
    if ngx.headers_sent then return nil, "response header already sent" end

    read_body()
    if http_ver() ~= 1.1 then return nil, "bad http version" end
	
    local headers = req_headers()
    local val = headers.upgrade
    if type(val) == "table" then val = val[1] end
    if not val or str_lower(val) ~= "socket" then
        return nil, "bad \"upgrade\" request header"
    end

    val = headers.connection
    if type(val) == "table" then val = val[1] end
    if not val or not str_find(str_lower(val), "upgrade", 1, true) then
        return nil, "bad \"connection\" request header"
    end

    local key = headers["sec-socket-key"]
    if type(key) == "table" then key = key[1] end
    if not key then return nil, "bad \"sec-socket-key\" request header" end

    local ver = headers["sec-socket-version"]
    if type(ver) == "table" then ver = ver[1] end
    if not ver or ver ~= "1" then return nil, "bad \"sec-socket-version\" request header" end

    local protocols = headers["sec-socket-protocol"]
    if type(protocols) == "table" then protocols = protocols[1] end
    if protocols then
        ngx_header["Sec-Socket-Protocol"] = protocols
    end
    ngx_header["Upgrade"] = "socket"

    local sha1 = sha1_bin(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
    ngx_header["Sec-Socket-Accept"] = base64(sha1)
    ngx_header["Content-Type"] = nil
    ngx.status = 101
	
    local ok, err = ngx.send_headers()
    if not ok then return nil, "failed to send response header: " .. (err or "unknonw") end
    
	ok, err = ngx.flush(true)
    if not ok then return nil, "failed to flush response header: " .. (err or "unknown") end

    local sock, err = req_sock(true)
    if not sock then return nil, err end

    local max_payload_len, send_masked, timeout
    if opts then
        max_payload_len = opts.max_payload_len
        send_masked = opts.send_masked
        timeout = opts.timeout

        if timeout then
            sock:settimeout(timeout)
        end
    end

    return setmetatable({
        sock = sock,
        max_payload_len = max_payload_len or 65535,
        send_masked = send_masked,
    }, mt)
end

function _M.set_timeout(self, time)
    local sock = self.sock
    if not sock then
        return nil, nil, "not initialized yet"
    end

    return sock:settimeout(time)
end

function _recv_frame(sock, max_payload_len)
    local data, err = sock:receive(2)
    if not data then
        return nil, nil, "failed to receive the first 2 bytes: " .. err
    end

    local opcode = band(byte(data, 1), 0xff)
    if (opcode >= 0x3 and opcode <= 0x7) or opcode >= 0xb then
        return nil, nil, "reserved non-control frames"
    end

    local mask = band(byte(data, 2), 0xff) ~= 0
	
	local data,err = sock:receive(4)
	if not data then
		return nil, nil, "failed to receive the 4 byte payload length: " .. (err or "unknown")
	end
	if band(byte(data, 1), 0x80) ~= 0 then
		return nil, nil, "payload len too large"
	end
	local payload_len = bor(lshift(byte(data, 1), 24), lshift(byte(data, 2), 16), lshift(byte(data, 3), 8), byte(data, 4))

    if payload_len > max_payload_len then
        return nil, nil, "exceeding max payload len"
    end

    local rest
    if mask then
        rest = payload_len + 4
    else
        rest = payload_len
    end

    local data
    if rest > 0 then
        data, err = sock:receive(rest)
        if not data then
            return nil, nil, "failed to read masking-len and payload: " .. (err or "unknown")
        end
    else
        data = ""
    end

    if opcode == 0x8 then
        -- being a close frame
        if payload_len > 0 then
            if payload_len < 2 then
                return nil, nil, "close frame with a body must carry a 2-byte" .. " status code"
            end

            local msg, code
            if mask then
                local fst = bxor(byte(data, 4 + 1), byte(data, 1))
                local snd = bxor(byte(data, 4 + 2), byte(data, 2))
                code = bor(lshift(fst, 8), snd)

                if payload_len > 2 then
                    -- TODO string.buffer optimizations
                    local bytes = new_tab(payload_len - 2, 0)
                    for i = 3, payload_len do
                        bytes[i - 2] = str_char(bxor(byte(data, 4 + i), byte(data, (i - 1) % 4 + 1)))
                    end
                    msg = concat(bytes)

                else
                    msg = ""
                end
            else
                local fst = byte(data, 1)
                local snd = byte(data, 2)
                code = bor(lshift(fst, 8), snd)
                if payload_len > 2 then
                    msg = sub(data, 3)
                else
                    msg = ""
                end
            end

            return msg, "close", code
        end

        return "", "close", nil
    end

    local msg
    if mask then
        -- TODO string.buffer optimizations
        local bytes = new_tab(payload_len, 0)
        for i = 1, payload_len do
            bytes[i] = str_char(bxor(byte(data, 4 + i), byte(data, (i - 1) % 4 + 1)))
        end
        msg = concat(bytes)
    else
        msg = data
    end

    return msg, types[opcode], nil
end

function _M.recv_frame(self)
    if self.fatal then
        return nil, nil, "fatal error already happened"
    end

    local sock = self.sock
    if not sock then
        return nil, nil, "not initialized yet"
    end

    local data, typ, err =  _recv_frame(sock, self.max_payload_len, true)
    if not data and not str_find(err, ": timeout", 1, true) then
		self.send_close(self,1000,err)
        self.fatal = true
    end
    return data, typ, err
end

local function build_frame(opcode, payload_len, payload, masking)
    -- XXX optimize this when we have string.buffer in LuaJIT 2.1
    local fst = band(opcode, 0xff)
	local snd = 0
    local masking_key
    if masking then
        -- set the mask bit
        snd = 1
        local key = rand(0xffffffff)
        masking_key = char(band(rshift(key, 24), 0xff), band(rshift(key, 16), 0xff), band(rshift(key, 8), 0xff), band(key, 0xff))

        -- TODO string.buffer optimizations
        local bytes = new_tab(payload_len, 0)
        for i = 1, payload_len do
            bytes[i] = str_char(bxor(byte(payload, i), byte(masking_key, (i - 1) % 4 + 1)))
        end
        payload = concat(bytes)
    else
        masking_key = ""
    end
	local extra_len_bytes = char(band(rshift(payload_len, 24), 0xff), band(rshift(payload_len, 16), 0xff),
                               band(rshift(payload_len, 8), 0xff), band(payload_len, 0xff))

    return char(fst, snd) .. extra_len_bytes .. masking_key .. payload
end

function _send_frame(sock, opcode, payload, max_payload_len, masking)
    if not payload then
        payload = ""
    elseif type(payload) ~= "string" then
        payload = tostring(payload)
    end

    local payload_len = #payload
    if payload_len > max_payload_len then return nil, "payload too big" end

    local frame = build_frame(opcode, payload_len, payload, masking)
    if not frame then return nil, "failed to build frame" end

    local bytes, err = sock:send(frame)
    if not bytes then return nil, "failed to send frame: " .. err end
    return bytes
end

function _M.send_frame(self, opcode, payload)
    if self.fatal then return nil, "fatal error already happened" end
    if not self.sock then return nil, "not initialized yet" end

    local bytes, err = _send_frame(self.sock, opcode, payload, self.max_payload_len, self.send_masked)
    if not bytes then
        self.fatal = true
    end
    return bytes, err
end

function _M.send_text(self, data)
    return self.send_frame(self, 0x1, data)
end

function _M.send_binary(self, data)
    return self.send_frame(self, 0x2, data)
end

function _M.send_close(self, code, msg)
    local payload
    if code then
        if type(code) ~= "number" or code > 0x7fff then
        end
        payload = char(band(rshift(code, 8), 0xff), band(code, 0xff))
                        .. (msg or "")
    end
    return self.send_frame(self, 0x8, payload)
end

function _M.send_ping(self, data)
    return self.send_frame(self, 0x9, data)
end

function _M.send_pong(self, data)
    return self.send_frame(self, 0xa, data)
end

return _M
