local model = require "include.role_model"
local config = require "include.config"
local timetool = require "include.timetool"
local floor = math.floor

local _M = model:extends()
_M.class = "role.extend"
_M.push_name  = "extend"
_M.changed_name_in_role = "extend"
_M.attrs = {
	ut ={},
	create = 0,
	logout = 0,
}

function _M:__up_version()
	local ct = timetool:now()
	if not self.data.create or self.data.create == 0 then self.data.create = ct end
	for k,v in pairs(config.update_obj) do
		if not self.data.ut[k] then
			self.data.ut[k] = v.dt or timetool:get_next_time(ct,v.ut)
		end
	end
end

function _M:get_create_time()
	return self.data.create
end

function _M:get_logout_time()
	return self.data.logout
end

function _M:offline(t)
	self.data.logout = t
	self:changed("logout")
end

function _M:get_update_time(typ)
	return self.data.ut[typ] or 0
end

function _M:can_update(typ)
	if not config.update_obj[typ] then return false end
	local ut = self.data.ut[typ]
	if ut and ut == 0 then return false end
	if not ut or ut < timetool:now() then return true end
	return false
end

function _M:pause_update(typ)
	if not config.update_obj[typ] then return end
	self.data.ut[typ] = 0
	self:changed("ut")
end

function _M:resume_update(typ,ut)
	if not config.update_obj[typ] then return end
	if self.data.ut[typ] and self.data.ut[typ] ~= 0 then return end
	if not ut then ut = timetool:now() end
	self.data.ut[typ] = timetool:get_next_time(ut,config.update_obj[typ].ut)
	self:changed("ut")
end

function _M:update(typ)
	if not self:can_update(typ) then return 0 end
	local upcount = 1
	local ct = timetool:now()
	self.data.ut[typ] = timetool:get_next_time(self.data.ut[typ],config.update_obj[typ].ut)
	if config.update_obj[typ].once then
		while self.data.ut[typ] < ct do
			upcount = upcount + 1
			self.data.ut[typ] = timetool:get_next_time(self.data.ut[typ],config.update_obj[typ].ut)
		end
	end
	self:changed("ut")
	return upcount
end

return _M