-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local t_concat = table.concat
local math_random = math.random
local md5 = ngx.md5
local string_upper = string.upper
local timetool = require "include.timetool"

local _M = {}

function _M:create_verifycode()
	local verifycode = {}
	math.randomseed(timetool:get_random_seed()) 
	for i = 1,16 do
		verifycode[i] = string.char(math_random(65,90))
	end
	return t_concat(verifycode)
end

function _M:login(uid,cid,cn,info)
	self[uid] = {
		cid = cid,
		cn = cn,
		info = info,
		time = timetool:now(),
		verifycode = self:create_verifycode()
	}
end

function _M:is_login(uid)
	if self:get_verifycode(uid) then return true end
	return false
end

function _M:logout(uid)
	self[uid] = nil
end

function _M:get_verifycode(uid)
	if not self[uid] then return false end
	if timetool:now() - self[uid].time > 60 then
		self[uid] = nil
		return false
	end
	return self[uid].verifycode
end

function _M:check_verify(uid,verify)
	local vc = self:get_verifycode(uid)
	if not vc then return false end
	local s = string_upper(md5(uid..vc))
	local d = string_upper(verify)
	if s ~= d then return false end
	self:logout(uid)
	return true
end

return _M