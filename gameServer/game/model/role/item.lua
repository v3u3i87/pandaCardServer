-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.item"
local mergeProfit = require "game.model.merge_profit"
local t_insert = table.insert
local task_config = require "game.template.task"

local _M = model:extends()
_M.class = "item"
_M.push_name  = "depot"
_M.changed_name_in_role = "depot"

_M.attrs = {
	p = 1,
	s = 1, --强化等级
	r = 0, --精炼等级
	d =0, --煅造等级
	u = 0,
	cost = {},
	e = 0, --经验(装备精炼, 配佩强化).
	sn =0, --强化次数
	rn=0,--精炼等级
}

function _M:__up_version()
	_M.super.__up_version(self)
	self.type = config:get_type(self.data.p)
end

function _M:on_time_up()
	self.data.sn =0
	self.data.rn =0
end

function _M:get_pid()
	return self.data.p
end

function _M:get_strong_lev()
	return self.data.s
end

function _M:get_strong_exp()
	return self.data.e
end

function _M:get_refine_lev()
	return self.data.r
end

function _M:get_forging_lev()
	return self.data.d
end

function _M:get_user_id()
	return self.data.u
end

function _M:inuse()
	return self.data.u ~= 0
end

function _M:wear(id)
	self.data.u = id
	self:changed("u")
end

function _M:take_off()
	self.data.u = 0
	self:changed("u")
end

function _M:strengthen(num,exp,cost)
	self.data.s = self.data.s + num
	self.data.sn = self.data.sn + num
	if exp >= 0 then 
		self.data.e = exp
		self:changed("e")
	end
	self:changed("s")
	self:append_cost(cost)
	self.role.tasklist:trigger(task_config.trigger_type.depot_strengthen,num)
	self.role.tasklist:trigger(task_config.trigger_type.depot_strengthen_maxlev)
end

function _M:refine(exp,cost)
	local num = 0
    if self.type == config.type.accessory then 
		self.data.r = self.data.r + 1
		self.data.rn = self.data.rn + 1
		self:changed("r")
		num = 1
	elseif self.type == config.type.equipment then
		self.data.e = self.data.e  + exp
		local bup = true
		while bup do
			bup = false
			local upexp = config:get_refine_levexp(self.data.p,self:get_refine_lev())
			if upexp <= self.data.e and upexp >0 then
				bup = true
				self.data.r = self.data.r + 1
				self.data.e = self.data.e - upexp
				self:changed("r")
				num = num +1
			end
		end
		self:changed("e")
	end
	self:append_cost(cost)
	self.role.tasklist:trigger(task_config.trigger_type.depot_refine,num)
	self.role.tasklist:trigger(task_config.trigger_type.depot_refine_maxlev,self.data.s)
end

function _M:forgingthen(cost)
	self.data.d = self.data.d + 1
	self:changed("d")
	self:append_cost(cost)
end

function _M:consume()
	if not self.role then return end
	if not self:inuse() then return end
	self.role.army:take_off_equipment(self.data.u, config:get_equipment_position(self:get_pid()))
end

function _M:reborn()
	self.data.s = 1
	self.data.r = 0
	self.data.d = 0
	self.data.e = 0
	self:changed()
	local cost = self:get_all_cost()
	self.data.cost = {}
	return cost
end

function _M:reclaim()
	if self:get_forging_lev() > 0 then return false end
	self.data.s = 1
	self.data.r = 0
	self.data.d = 0
	self.data.e = 0
	self:changed()
	local cost = self:get_all_cost()
	self.data.cost = {}
	local reclaim_profit = config:get_reclaim_profit(self.data.p)
	local cost_acc_profit = {}
	if config:get_type(self.data.p) == config.type.accessory then
		for i,v in pairs(cost) do
			local ap = config:get_reclaim_profit(i)
			for n=1,v do
				t_insert(cost_acc_profit,ap)
			end
			cost[i] = nil
		end
	end
	return mergeProfit(cost,reclaim_profit,unpack(cost_acc_profit))
end

function _M:get_full_attributes()
	return config:get_full_attributes(self:get_pid(),self.data)
end

return _M