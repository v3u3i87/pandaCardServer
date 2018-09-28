-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.alliancegirl"
local timetool = require "include.timetool"
local task_config = require "game.template.task"
local int = math.floor
local min = math.min

local toIntHash = require "include.tointhash"

local _M = model:extends()
_M.class = "role.alliancegirl"
_M.push_name  = "alliancegirl"
_M.changed_name_in_role = "alliancegirl"
_M.attrs = {
	normal = 0,
	--special = 0,
	tryst_num = config.tryst_num_max,
	profit_normal = 0,
	profit_special = {0,0},
	s =0,
}

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.data.special then self.data.special = 0 end
	if self.data.special and type(self.data.special) == "table"  then 
		local special =0
		self.data.special = special
	end
end

function _M:can_tryst()
	return self.data.tryst_num > 0 
end

function _M:tryst()
	self.data.normal = self.data.normal + 1
	--local normal_max = config:get_endprogress(self.data.normal +1)
	--self.data.normal = min(self.data.normal,normal_max)
	self.data.tryst_num = self.data.tryst_num - 1
	self.data.s = self.data.s + 1
	self.role.extend:resume_update("girl_tryst")
	self:changed()
	self.role.tasklist:trigger(task_config.trigger_type.alliancegirl_tryst,1)
end

function _M:can_get_reward(id)
	local typ = config:get_special_type(id)
	--ngx.log(ngx.ERR,"id:",id," self.data.profit_normal:",self.data.profit_normal," self.data.normal:",self.data.normal)
	if typ == config.profit_type.normal then
	 	if self.data.profit_normal +1 == id and config:can_normal_profit(id,self.data.normal)  then return true end
	elseif typ == config.profit_type.special then
		local profit_index = config:get_special_index(id)
		if profit_index == 0 then return false end
		if self.data.profit_special[profit_index] == 0 and config:can_normal_profit(id,self.data.special) then return true end
	end
	return false
end

function _M:get_reward(id)
	local typ = config:get_special_type(id)
	self.role.tasklist:trigger(task_config.trigger_type.alliancegirl_getreward,1)

	if typ == config.profit_type.normal then
		self.data.normal = 0
		self.data.profit_normal = self.data.profit_normal +1
		self:changed("normal")
		self:changed("profit_normal")
	elseif typ == config.profit_type.special then
		local profit_index = config:get_special_index(id)
		self.data.profit_special[profit_index] = 1
		self:changed("profit_special")
	end
	return config:get_reward(id)
end

function _M:charge(num)
	--num = int(num/10)
	self.data.normal = self.data.normal + num
	self.data.special = self.data.special + num

	self:changed("normal")
	self:changed("special")
	self.role.tasklist:trigger(task_config.trigger_type.alliancegirl_tryst,num)
end

function _M:reply_tryst_num(count)
	self.data.tryst_num = self.data.tryst_num + count
	if self.data.tryst_num >= config.tryst_num_max then 
		self.data.tryst_num = config.tryst_num_max
		self.role.extend:pause_update("girl_tryst")
	end
	self:changed("tryst_num")
end

function _M:reset_special()
	--[[if #self.data.profit_special >0 then
		for i,v in pairs(self.data.profit_special) do
			self.data.profit_special[v] = 0
		end
	end]]--
	self.data.profit_special = {0,0}
	self.data.special = 0

	self:changed("special")
	self:changed("profit_special")
end

function _M:get_profit()
	local fid = config:get_normal_profit_maxid(self.data.normal)
	if fid > self.data.profit_normal then
		for i=self.data.profit_normal+1,fid do
			local profit = config:get_normal_profit_by_id(i)
			if profit then self.role:gain_resource(profit) end
		end
		self.data.profit_normal = fid
		self:changed("profit_normal")
	end
	for i,v in ipairs(config:get_special_ids()) do
		if self.data.profit_special[v] == 0 and config:can_get_special_profit(v,self.data.special[v]) then
			local profit = config:get_special_profit(v)
			if profit then self.role:gain_resource(profit) end
			self.data.profit_special[v] = 1
			self:changed("profit_special")
		end
	end
end

function _M:get_num(t)
	local n =0
	if t ==1 then n = self.data.s
	elseif t == 2 then n = self.data.profit_normal
	end
	return n
end


return _M