-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local timetool = require "include.timetool"
local config = require "game.config" 

local _M = model:extends()
_M.class = "friend"
_M.push_name  = "friends"
_M.changed_name_in_role = "friends"
_M.attrs = {
	info = {
		id = 0,
		name = "",
		lev = 1,
		atk = 0,
		un = "",
		on = 1,
	},
	f = 0,
	typ =1 ,--1申请２好友3.黑名单 0.未批准
	g  = 1, --1未赠送2.已赠送
	r = 0,  --1未领取2.已领取
}

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.id and self.data.info then self.id = self.data.info.id end
end

function _M:is_append()
	return self.data.typ == 1
end

function _M:is_friend()
	return self.data.typ == 2
end

function _M:is_blacklist()
	return self.data.typ == 3
end

function _M:get_type()
	return self.data.typ
end

function _M:make_firends()
	self.data.typ = 2
	self:changed("typ")
end

function _M:make_blacklist()
	self.data.typ = 3
	self:changed("typ")
end

function _M:make_append()
	self.data.typ = 1
	self:changed("typ")
end

function _M:get_level()
	return self.data.info.lev
end

function _M:set_level(lev)
	self.data.info.lev = lev
	self:changed("info")
end

function _M:get_name()
	return self.data.info.n
end

function _M:set_name(name)
	self.data.info.n = name
	self:changed("info")
end

function _M:get_friendly()
	return self.data.f
end

function _M:add_friendly(f)
	self.data.f = self.data.f + f
	self:changed("f")
end

function _M:on_time_up()
	self.data.g = 1
	self.data.r = 0
	self:changed("g")
	self:changed("r")
end

function _M:is_give()
	return self.data.g == 2
end

function _M:set_give()
	self.data.g = 2
	self:changed("g")
end

function _M:is_receive()
	return self.data.r == 2
end

function _M:set_receive(value)
	self.data.r = value
	self:changed("r")
end

function _M:update()
	local roleMgr = require "manager.roleMgr"
	local frole = roleMgr:get_role(self.id)
	if not frole then return end
	local l = frole:get_level()
	local bchange = false
	if l ~= self:get_level() then
		self:set_level(l)
	end
	local n = frole:get_name()
	if n ~= self:get_name() then
		self:set_name(n)
	end
end

return _M