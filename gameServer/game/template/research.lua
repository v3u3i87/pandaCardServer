-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local math_random = math.random

local _M = {}
_M.data = {
	card = config.template.card,
	rand = {},
	ghero = {},
	continue = {
		[1] = 10,
		[2] = 10,
		[3] = 10,
	},
}

_M.lottery_type = {
	normal_one = 1,
	diamond_one = 2,
	diamond_ten = 3,
}

_M.cost_res_type = {
	gem = 1,
	goods = 2,
}

function _M:get(id)
	return self.data.card[id]
end

function _M:get_rand_data(id)
	if not self.data.rand[id] then
		self.data.rand[id] = {}
		self.data.rand[id].n = 0
		self.data.rand[id].cards = self:get(id).probability
		for i,v in pairs(self.data.rand[id].cards) do
			self.data.rand[id].n = self.data.rand[id].n + v[1]
		end
	end
	return self.data.rand[id]
end

function _M:get_ghero_data(id)
	if not self.data.ghero[id] then
		self.data.ghero[id] = {}
		self.data.ghero[id].n = 0
		self.data.ghero[id].cards = self:get(id).ghero
		for i,v in pairs(self.data.ghero[id].cards) do
			self.data.ghero[id].n = self.data.ghero[id].n + v[1]
		end
	end
	return self.data.ghero[id]
end

function _M:lottery_one(id,count)
	local cid = 0
	local rand_data={}
	if count == 0 and (id == 1 or id ==2) then cid = self.data.card[id].first or 1020
	else
		if count % self.data.continue[id] == 0 then
			rand_data = self:get_ghero_data(id)
		else
			rand_data = self:get_rand_data(id)
		end
		local r1 = math_random(1,rand_data.n)
		local idx = 0
		for i,v in ipairs(rand_data.cards) do
			if r1 < v[1] then
				idx = i
				break;
			end
			r1 = r1 - v[1]
		end
		if idx == 0 then return false end
		local r2 = math_random(1,#rand_data.cards[idx][2])
		cid = rand_data.cards[idx][2][r2]
	end
	return cid
end

function _M:lottery(id,count,num)
	local profit = {}
	for i=1,num do
		local p = self:lottery_one(id,count)
		count = count + 1
		if p then
			profit[p] = (profit[p] or 0) + 1
		end
	end
	return profit
end

function _M:get_lottery_cost(id,typ)
	local data={}
	if typ == self.cost_res_type.gem then
		local n = self:get(id).gem
		if n == -1 then return false end
		data[config.resource.diamond] = n
	else
		local p = self:get(id).goods
		if p == -1 then return false end
		if type(p) == "table" and #p >1 then
			data[ p[1] ] = p[2] end
	end
	return data
end 

return _M