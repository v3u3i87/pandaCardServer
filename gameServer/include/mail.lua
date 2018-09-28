local model = require "include.role_model"

local _M = model:extends()
_M.class = "mail"
_M.push_name  = "mail"
_M.attrs = {
	t = 0,
	s = 0,
	r = 0,
	h = "",
	c = "",
	p = {},
}

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
	self:changed()
end

function _M:read()
	if self.data.s == 0 then
		self.data.s = 1
		self:changed()
	end
end

function _M:attachment()
	if self.data.s == 0 or self.data.s == 1 then
		self.data.s = 2
		self:changed()
	end
end

return _M