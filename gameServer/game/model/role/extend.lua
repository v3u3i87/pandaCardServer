-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.config"
local timetool = require "include.timetool"
local stageConfig = require "game.template.stage"
local floor = math.floor

local _M = model:extends()
_M.class = "role.extend"
_M.push_name  = "extend"
_M.changed_name_in_role = "extend"
_M.attrs = {
	offline = 0,
	ut ={},
	create_time = 0,
}

function _M:__up_version()
	_M.super.__up_version(self)
	local ct = timetool:now()
	if not self.data.create_time or self.data.create_time == 0 then self.data.create_time = ct end
	for k,v in pairs(config.update_obj) do
		if not self.data.ut[k] then
			self.data.ut[k] = v.dt or timetool:get_next_time(ct,v.ut)
			self:changed("ut")
		end
	end
end

function _M:get_create_time()
	return self.data.create_time
end

function _M:offline(t)
	self.data.logouttime = t
	self:changed("logouttime")
end

function _M:calc_offline()
	if not self.role or not self.data.logouttime then return end
	local ot = timetool:now() - self.data.logouttime
	if ot < 60 then return end
	ot = ot + self.data.offline * 60
	local maxt = 6*3600
	if self.role.base:has_month_card() then
		maxt = maxt + 6*3600
	end
	if self.role.base:has_life_card() then
		maxt = maxt + 6*3600
	end
	if ot > maxt then ot = maxt end
	self.data.offline = floor(ot / 60)
	self:changed("offline")
end

function _M:has_offline_profit()
	return self.data.offline > 0
end

function _M:get_offline_profit()
	if not self.role or not self:has_offline_profit() then return end
	local profit = stageConfig:get_offline_profit(self.role.base:get_stage(),self.data.offline)
	if not profit then return end
	local mx = 1
	local ex = 1
	if self.role.base:has_month_card() then
		mx = mx + 0.1
		ex = ex + 0.2
	end
	if self.role.base:has_life_card() then
		mx = mx + 0.1
		ex = ex + 0.2
	end
	profit[config.resource.money] = floor(profit[config.resource.money] * mx)
	profit[config.resource.exp] = floor(profit[config.resource.exp] * ex)

	return profit
end

function _M:receive_offline_profit()
	local profit = self:get_offline_profit()
	if self.role and profit then
		self.role:gain_resource(profit)
		self.data.offline = 0
		self:changed("offline")
		return profit
	end
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