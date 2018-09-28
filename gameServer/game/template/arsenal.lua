-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local math_random = math.random
local table_insert = table.insert

local _M = {}
_M.data = {
	arsen = config.template.arsen,
	rand1 = {},
	box ={},
}
_M.box_type = {8,15,20,24}
_M.interval_time	= 5400		--1.5小时会自动恢复1次
_M.arsen_max_n_num = 5


function _M:get_box_rand(id)
	if not self.data.box[id] then
		self.data.box[id] = {}
		self.data.box[id].n = 0
		self.data.box[id].rewards = self.data.arsen[id].boxreward
		for i,v in pairs(self.data.box[id].rewards) do
			self.data.box[id].n = self.data.box[id].n + v[1]
		end
	end
	return self.data.box[id]
end


function _M:get_box(id)
	local rand_data = self:get_box_rand(id)
	-- [[10,[20025,20026,20027,20028,20029,20030,20031,20032,20033,20034,20035,20036],1],[990,[20021,20022,20023,20024],1]]
	local r1 = math_random(1,rand_data.n)
	local idx = 0
	for i,v in ipairs(rand_data.rewards) do
		if r1 < v[1] then
			idx = i
			break;
		end
		r1 = r1 - v[1]
	end
	if idx == 0 then return false end
	local r2 = math_random(1,#rand_data.rewards[idx][2])
	return  { [ rand_data.rewards[idx][2][r2] ] = rand_data.rewards[idx][3] }
end

function _M:get_box_type(pos)
	return self.data.arsen[pos].quality
end


function _M:get_rand_rand1(id)
	if not self.data.rand1[id] then
		self.data.rand1[id] = {}
		self.data.rand1[id].n = 0
		self.data.rand1[id].rewards = self.data.arsen[id].stagereward
		for i,v in pairs(self.data.rand1[id].rewards) do
			self.data.rand1[id].n = self.data.rand1[id].n + v[1]
		end
	end
	return self.data.rand1[id]
end

function _M:challeng_one_reward(pos)
	if not self.data.arsen[pos] or not self.data.arsen[pos].reward then return false end
	local r1 = math_random(1,#self.data.arsen[pos].reward[1])
	return self.data.arsen[pos].reward[1][r1],self.data.arsen[pos].reward[2]
end


function _M:challeng_one(id)
	local rand1_data = self:get_rand_rand1(id)
	local r1 = math_random(1,rand1_data.n)
	local idx = 0
	for i,v in pairs(rand1_data.rewards) do
		if r1 < v[1] then
			idx = i
			break;
		end
		r1 = r1 - v[1]
	end
	if idx == 0 then return false end
	local rand2_data = rand1_data.rewards[idx][2]
	--[ [[21009,21010,21011,21012],5,1000]]
	local idall ={}
	local num = {}
	local pro = {}
	local numall = 0
	for i,v in pairs(rand2_data) do
		table_insert(idall,v[1])
		table_insert(num,v[2])
		table_insert(pro,v[3])
		numall = numall + v[3]
	end
	local r2 = math_random(1,numall)
	local idx2 = 0
	for i,v in ipairs(pro) do
		if r2 < v then
			idx2 = i
			break;
		end
		r2 = r2 - v
	end
	if idx2 == 0 then return false end
	--local rand3_data = rand2_data[idx2]
	--[ [21009,21010,21011,21012],5,1000]
	local r3 =  math_random(1,#rand2_data[idx2][1])
	return rand2_data[idx2][1][r3] or rand1_data.rewards[1][2][1][1][1]  ,rand2_data[idx2][2] or rand1_data.rewards[1][2][1][2]
end

function _M:get_profit(pos,count)
	local profit = {}
	local profitadd ={}
	for i=1,count do
		local profitone = {}
		local id,num = self:challeng_one(pos)
		profit[id] = (profit[id] or 0) + num
		profitone[id] = (profitone[id] or 0) + num
		local id,num = self:challeng_one_reward(pos)
		if id >0 and num >0 then
			profit[id] = (profit[id] or 0) + num
			profitone[id] = (profitone[id] or 0) + num
		end
		table_insert(profitadd,profitone)
	end
	return profit,profitadd
end


function _M:check_challenge_level(pos,level)
	return self.data.arsen[pos].level <= level
end

function _M:get_box_need_count(pos,g_num)
	return self.data.arsen[pos].times[1] +   self.data.arsen[pos].times[2] * g_num 
end

function _M:get_buy_num_cost(buy_num,num)
	--return self.data.buy_cost[buy_num+1].cost
	return {[config.resource.diamond] = 30 * num}
end

function _M:get_max_buy(vip)
	if not vip then vip = 0 end
	return 5
	--return self.data.buy_cost[vip].arsen_max_b_mum or 5
end

function _M:get_max_num(vip)
	if not vip then vip = 0 end
	return 5
	--return self.data.buy_cost[vip].arsen_max_n_num or 5
end

return _M