-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.item"
local Cconfig = require "game.template.commander"
local t_insert = table.insert
local math_floor = math.floor

local _M = model:extends()
_M.class = "car"
_M.push_name  = "commanders"
_M.changed_name_in_role = "commanders"

_M.cost_pro = 80 --

_M.attrs = {
	id = 0,
	lv = 1,
	star = 0,
	st = 0,
	exp =0,
	cost = {},
}

function _M:__up_version()
	_M.super.__up_version(self)
end

function _M:get_pid()
	return self.data.id
end

function _M:get_level()
	return self.data.lv
end

function _M:get_exp()
	return self.data.exp
end

function _M:get_star()
	return self.data.star
end

function _M:get_strengthen()
	return self.data.st
end


function _M:level_up(add_exp,cost)
	self.data.exp = self.data.exp + add_exp
	local up = Cconfig:get_car_level_up_exp(self.data.id,	self.data.lv)
	while self.data.exp >= up do
		self.data.exp = self.data.exp - up
		self.data.lv = self.data.lv + 1
		if self.data.lv >= Cconfig:get_car_max_level() then self.data.exp = 0 end
		up = Cconfig:get_car_level_up_exp(self.data.id,	self.data.lv)
	end
	self:changed("exp")
	self:changed("lv")

	self:append_cost(cost)
end

function _M:star_up(cost)
	self.data.star = self.data.star + 1
	self:changed("star")
	self:append_cost(cost)
end

function _M:strengthen(cost)
	self.data.st = self.data.st + 1
	self:changed("st")
	self:append_cost(cost)
end

function _M:consume()
	if not self.role then return end
	if not self:inuse() then return end
	self.role.army:take_off_equipment(self.data.u, config:get_equipment_position(self:get_pid()))
end

function _M:reborn()
	self.data.lv = 1
	self.data.star = 0
	self.data.st = 0
	self.data.exp = 0
	self:changed()
	local cost = self:get_all_cost_pro(self.cost_pro)
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

return _M