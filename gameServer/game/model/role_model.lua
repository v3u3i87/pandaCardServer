-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "include.role_model"
local config = require "game.config"
local tointhash = require "include.tointhash"
local math_floor = math.floor
local table_insert  = table.insert
local math_min = math.min
local _M = model:extends()

function _M:__up_version()
	_M.super.__up_version(self)
	if self.data.cost then 
		self.data.cost = tointhash(self.data.cost)
		for i,v in pairs(self.data.cost) do
			if type(v) ~= "number" then self.data.cost[i] = nil end
		end
	end
end

function _M:get_client_data()
	local data = _M.super.get_client_data(self)
	data.cost = nil
	return data
end

function _M:append_cost(cost,bch)
	if not self.data.cost or not cost then return end

	if bch then
		for id,num in pairs(cost) do
			self.data.cost[id] = (self.data.cost[id] or 0) + num
		end
	else
		if cost.money then

			self.data.cost[config.resource.money] = (self.data.cost[config.resource.money] or 0) + cost.money
		end
		
		if cost.diamond then
			self.data.cost[config.resource.diamond] = (self.data.cost[config.resource.diamond] or 0) + cost.diamond
		end
		
		if cost.virtual then
			for t,n in pairs(cost.virtual) do
				self.data.cost[t] = (self.data.cost[t] or 0) + n
			end
		end
		
		if cost.knapsack then
			for t,n in pairs(cost.knapsack) do
				self.data.cost[t] = (self.data.cost[t] or 0) + n
			end
		end
		
		if cost.depot then
			for id,item in pairs(cost.depot) do
				local pid = item:get_pid()
				self.data.cost[pid] = (self.data.cost[pid] or 0) + 1
				self:append_cost(item:get_all_cost(),true)
			end
		end
		
		if cost.soldiers then
			for pid,num in pairs(cost.soldiers) do
				self.data.cost[pid] = (self.data.cost[pid] or 0) + num
			end
		end
		
		if cost.commanders then
			for id,commander in pairs(cost.depot) do
				local pid = commander:get_pid()
				self.data.cost[pid] = (self.data.cost[pid] or 0) + 1
				self:append_cost(commander:get_all_cost(),true)
			end
		end
	end
	
end

function _M:get_all_cost()
	return self.data.cost
end

function _M:on_level_up(level)
end

function _M:on_vip_up(vip)
end

function _M:on_time_up( )
end

function _M:clear_data()
	-- body
end

function _M:get_all_cost_pro(pro)
	if not pro then pro = 100 end
	local cost = {}
	for k,v in pairs(self.data.cost) do
		cost[k] = math_floor(( v * pro) /100)
	end
	return cost
end

function _M:get_use_data()
	local data = {}
	for i,v in pairs(self.data) do
		if v.inuse and v:inuse() then 
			--table_insert(data,v:get_client_data()) 
			data[v:get_id()] = v:get_client_data()
		end
	end
	return data
end

function _M:virtula_add_count(num)
end

function _M:use_virtaul(num)
	local item_num = self.role.virtual:get_num(self.virtual_id) or 0
	if item_num >0 then self.role.virtual:use(self.virtual_id,math_min(num,item_num)  ) end
end

return _M