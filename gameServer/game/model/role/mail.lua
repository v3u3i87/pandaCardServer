-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"

local _M = model:extends()
_M.class = "mail"
_M.push_name  = "mailbox"
_M.changed_name_in_role = "mailbox"
_M.attrs = {
	t = 0,
	s = 0,
	r = 0,
	h = "",
	c = "",
	p = {},
}


function _M:__up_version()
	_M.super.__up_version(self)
	if (self.data.p and type(self.data.p) == "table") then
		local np = {}
		for i,v in pairs(self.data.p) do
			np[tonumber(i)] = v
		end
		self.data.p = np
	end

end

function _M:get_type()
	return self.data.t
end

function _M:get_head()
	return self.data.h
end

function _M:get_content()
	return self.data.c
end

function _M:get_attachment()
	return self.data.p
end

function _M:get_receive_time()
	return self.data.r
end

function _M:set_receive_time(t)
	self.data.r = t
	self:changed("r")
end

function _M:has_attachment()
	if not self.data.p then return false end
	for i,v in pairs(self.data.p) do
		return true
	end
	return false
end

function _M:read()
	if self.data.s == 0 then
		self.data.s = 1
		self:changed("s")
	end
end

function _M:attachment()
	if self.data.s == 0 or self.data.s == 1 then
		self.data.s = 2
		self:changed("s")
	end
end

return _M