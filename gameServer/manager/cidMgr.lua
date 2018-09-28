-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local t_concat = table.concat
local math_random = math.random
local string_upper = string.upper
local timetool = require "include.timetool"
local aes = require "resty.aes"
local s_split = require "include.stringsplit"
local cjson = require "include.cjson"
local tonumber = tonumber

local _M = {}
_M.key = "Rh%5%e@AP@L2@SIc"

function _M:create_verifycode(cid)
	local verifycode = cid .. "_" ..  timetool:now() .. "_" .. math_random(65,90)
	ngx.log(ngx.ERR,"verifycode:",verifycode)
	local aes_128_cbc_with_iv = aes:new(_M.key, nil, aes.cipher(128,"cbc"), {iv="1234567890123456"})
    local encrypted = aes_128_cbc_with_iv:encrypt(verifycode)
    return ngx.encode_base64(encrypted)
end

function _M:login_key(cid)
	local key = self:create_verifycode(cid)
	self[cid] = {
		cid = cid,
		time = timetool:now(),
		key = key
	}
	ngx.log(ngx.ERR,"key:",key)
	return key
end

function _M:is_login(cid)
	if self:get_verifycode(cid) then return true end
	return false
end

function _M:logout(cid)
	self[cid] = nil
end

function _M:get_verifycode(cid)
	if not self[cid] then return false end
	if timetool:now() - self[cid].time > 60 then
		self[cid] = nil
		return false
	end
	return self[cid].key
end

function _M:check_verify(cid,verify)
	local vc = self:get_verifycode(cid)
	if not vc then return false end
	local verify = ngx.decode_base64(verify)
	local aes_128_cbc_with_iv = aes:new(_M.key, nil, aes.cipher(128,"cbc"), {iv="1234567890123456"})
    local decrypt_verify= aes_128_cbc_with_iv:decrypt(verify)
	ngx.say(" decrypt_verify:",decrypt_verify)
	local s = s_split(decrypt_verify,"[_ :]",true)
	ngx.log(ngx.ERR,"s:",cjson.encode(s))
	if not s[1] or tonumber(s[1]) ~= cid then return false end
	if not s[2] or tonumber(s[2])  < timetool:now() - 60 then return false end
	if not s[3] or tonumber(s[3]) > 60 then return false end
	return true
end

return _M