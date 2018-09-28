-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local t_insert = table.insert
local t_sort = table.sort

local _M = {}
_M.data = {
	profit = config.template.alliancegirl
}
_M.tryst_num_max = 2
_M.profit_type = {
	normal = 1,
	special = 2,
}

function _M:__init()
	self.data.p_normal = {}
	self.data.special_ids = {}
	local np = 0
	for i,v in ipairs(self.data.profit) do
		v.item = config:change_cost(v.item)
		if v.type == self.profit_type.normal then
			--v.endprogress = v.endprogress + np
			--np = v.endprogress
			t_insert(self.data.p_normal,v)
		else
			t_insert(self.data.special_ids,v.id)
		end
	end
	t_sort(self.data.p_normal,function(a,b) return a.endprogress < b.endprogress end)
end

function _M:get_special_ids()
	return self.data.special_ids
end

function _M:get_normal_profit_maxid(fav)
	for i,v in ipairs(self.data.p_normal) do
		if v.type == typ then
			if fav < v.endprogress then
				return i - 1
			end
		end
	end
	return 0
end

function _M:get_normal_profit_by_id(id)
	if not self.data.p_normal[id] then return false end
	return self.data.p_normal[id].item
end

function _M:can_get_special_profit(id,progress)
	if not self.data.profit[id] or self.data.profit[id].type ~= self.profit_type.special then return false end
	return self.data.profit[id].endprogress <= progress
end

function _M:get_special_profit(id)
	if not self.data.profit[id] or self.data.profit[id].type ~= self.profit_type.special then return false end
	return self.data.profit[id].item
end


function _M:get_special_type(id)
	return self.data.profit[id].type or 0
end

function _M:can_normal_profit(id,value)
	--ngx.log(ngx.ERR,"id:",id," value:",value)
	if not self.data.profit[id] then return false end
	--ngx.log(ngx.ERR,"self.data.profit[id].endprogress:",self.data.profit[id].endprogress)
	if self.data.profit[id].endprogress > value then return false end
	return true
end

function _M:get_reward(id)
	return self.data.profit[id].item
end

function _M:get_endprogress(id)
	return self.data.profit[id].endprogress or 0
end

function _M:init_special()
	if not self.special_index then
		self.special_index = {}
		local index = 1
		for i,v in ipairs(self.data.profit) do
			if v.type == self.profit_type.special then
				self.special_index[i] = index
				index = index + 1
			end
		end
	end
	return self.special_index
end


function _M:get_special_index(id)
	self:init_special()
	local index = 0
	if not self.data.profit[id] or self.data.profit[id].type ~= self.profit_type.special or not self.special_index[id]
		then return index end
	return self.special_index[id]
end

return _M