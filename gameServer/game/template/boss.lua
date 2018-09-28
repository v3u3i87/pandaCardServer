-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local timetool = require "include.timetool"
local cjson = require "include.cjson"
local math_random = math.random
local math_ceil = math.ceil
local math_min = math.min
local table_insert = table.insert
local math_floor = math.floor


local _M = {}
_M.data = {
	rank = config.template.bossranklist,
	award = config.template.bossawardlist,
	attribute = config.template.bossattribute,
	stage = config.template.stage,
	shop = config.template.shop,
	rand = {},
	hp = {},
}

_M.boss_challenge_free_max = 10
_M.boss_add_challenge_interval = 7200
_M.boss_challage_time = 30  --600
_M.boss_time = 3600
_M.boss_refresh_free = 4
_M.boss_refresh_max = 8
_M.boss_add_refresh_interval = 3600
_M.boss_stage_id = "敌将"
_M.boss_stagetype = 4
_M.boss_challage_id = 11
_M.refresh_cost_id = 12

function _M:__init()
	local ids={}
	for k,v in pairs(self.data.attribute) do
		ids[k] = v.stage
	end
	for k,v in pairs(ids) do
		v = v%100
		local stage_data = self.data.stage[self.boss_stage_id .. v][self.boss_stagetype]
		local one_hp =0
		if stage_data then
			for k1,v1 in ipairs(stage_data.bossrate) do
				one_hp = one_hp + v1[1]
			end
		end
		self.data.hp[v] = one_hp
	end
end

function _M:get_profit(id)
	if self.data.attribute[id] then
		return 	{  [ self.data.attribute[id].drop[1] ]  = self.data.attribute[id].drop[2]}	
	end
end

function _M:get_rand_boss( )
	return math_random(1,#self.data.attribute) 
end
	--9.	每天12点到14点，全力一击挑战卷消耗减半
	--10.	每天18点到20点，获得的功勋*2
function _M:get_challage_cost_num(typ)
	local cost_num = 1
	if typ == 2 then
		local hour = timetool:get_hour()
		if hour < 12 or hour >= 14 then cost_num = 2 end
	end
	return cost_num	
end
function _M:get_challage_add_exploit(damage)
	--local exploit = math_ceil(damage / 3500) 
	--BOSS战功勋计算奖励由原来的伤害/3500修改为  【20000基础值+照成伤害/100000】
	local exploit = 20000 + math_floor(damage / 100000) 
	if exploit <= 0 then return 0 end
	local hour = timetool:get_hour()
	if hour >= 18 and hour < 20 then exploit = exploit * 2 end
	return exploit	
end

function _M:boss_hp(id)
	return self.data.hp[id%100]
end


function _M:get_explot(id)
	if not self.data.award[id] then return false end
	--ngx.log(ngx.ERR,cjson.encode(self.data.award[id].item),"======type:",type(self.data.award[id].item))
	return true,config:change_cost_num(self.data.award[id].item)
end

function _M:can_get_explot(id,explot)
	return self.data.award[id].endprint <= explot
end

--1.	钻石补充每次2钻，每次回复一点挑战点
--2.	后续每2次增加2钻
--3.	最大100钻为上限
function _M:get_diamond(count)
	--return math_min(100,2 + math_ceil(count /2) * 2) or 0
	return math_min(100,6 + math_floor((count-1) /2) * 2) or 6
end

--卷每次消耗一次一张 卷ID 10
--碎片一次20个。  碎片ID 12
function _M:get_refresh_cost(typ)
	local cost = {}
	if typ == 1 then cost[10] = 1
	elseif typ == 2 then cost[self.refresh_cost_id] = 20 end
	return cost
end

function _M:get_pricetype1_data()
	if not self.pricetype1 then
		self.pricetype1  = {}
		self.pricetype1_pro ={}
		self.pricetype1_n = 0
		for k,v in pairs(self.data.shop) do
			table_insert(self.pricetype1,v.pricetype1)
			self.pricetype1_n =  self.pricetype1_n + v.pricetype1[3]
			table_insert(self.pricetype1_pro,self.pricetype1_n)
		end
	end
	return self.pricetype1
end

function _M:get_pricetype2_data()
	if not self.pricetype2 then
			self.pricetype2  = {}
			self.pricetype2_pro ={}
			self.pricetype2_n = 0
			for k,v in pairs(self.data.shop) do
				table_insert(self.pricetype2,v.pricetype2)
				self.pricetype2_n =  self.pricetype2_n + v.pricetype2[3]
				table_insert(self.pricetype2_pro,self.pricetype2_n)
			end
		end
	return self.pricetype2
end

function _M:refresh_pricetype1()
	self:get_pricetype1_data()
	local r =  math_random(1,self.pricetype1_n)
	local idx = 0
	for i,v in ipairs(self.pricetype1_pro) do
		if r < v then
			idx = i
			break;
		end
		r = r - v
	end
	if idx == 0 then return false end
	idx = idx + 800
--	ngx.log(ngx.ERR,"idx:",idx .. " self.pricetype1[idx][1]:" , self.pricetype1[idx][1] .. " self.pricetype1[idx][2]:" , self.pricetype1[idx][2])
	return self.data.shop[idx].index,1,self.data.shop[idx].discount
end

function _M:refresh_pricetype2()
	self:get_pricetype2_data()
	local r =  math_random(1,self.pricetype2_n)
	local idx = 0
	for i,v in ipairs(self.pricetype2_pro) do
		if r < v then
			idx = i
			break;
		end
		r = r - v
	end
	if idx == 0 then return false end
	idx = idx + 800
--	ngx.log(ngx.ERR,"idx:",idx .. " self.pricetype2[idx][1]:" , self.pricetype2[idx][1] .. " self.pricetype2[idx][2]:" , self.pricetype2[idx][2])
	return self.data.shop[idx].index,2,self.data.shop[idx].discount
end

--eq 物品id
--b pricetype1
--n num

function _M:refresh_item()
	local eq = {}
	local b={}
	local n={}
	--其中三个为道具购买，三个为钻石购买
	for i=1,3 do
		local eq1,b1,n1= self:refresh_pricetype1()
		table_insert(eq,eq1)
		table_insert(b,b1)
		table_insert(n,n1)
	end
	for i=1,3 do
		local eq1,b1,n1= self:refresh_pricetype2()
		table_insert(eq,eq1)
		table_insert(b,b1)
		table_insert(n,n1)
	end
	return eq,b,n
end

function _M:get_rand_data(id)
	if not self.data.rand[id] then
		self.data.rand[id] = {}
		self.data.rand[id].n = 0
		self.data.rand[id].cards = self.data.shop[id].pricetype 
		-- [[22076,100，5000],[1,100，2000]]
		for i,v in pairs(self.data.rand[id].cards) do
			self.data.rand[id].n = self.data.rand[id].n + v[3]
		end
	end
	return self.data.rand[id]
end

function _M:rand_one(id)
	local cid = 0
	local rand_data= self:get_rand_data(id)
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
	return cid
end



function _M:get_can_buy_cost(id,typ)
	local cost ={}
	local price = {}
	id = id % 800
	if typ == 1 then 
		self:get_pricetype1_data()
		price = self.pricetype1[id]
	elseif typ == 2 then
		self:get_pricetype2_data()
		price = self.pricetype2[id]
	end
	if #price < 0 then return false end
	cost = { [price[1] ]  = price[2] }
	return cost
end

function _M:get_buy_item(id)
	local profit ={}
	profit = { [self.data.shop[id].id ]  = 1 }
	return profit
end


function _M:get_range_reward()
	local range = {}
	local profit ={}
	for k,v in ipairs(self.data.rank) do
		local lrang ={}
		table_insert(lrang,v.rank[1])
		table_insert(lrang,v.rank[2])
		table_insert(range,lrang)
		table_insert(profit, {[ v.item[1] ] =  v.item[2]})
	end
	return range,profit
end

function _M:get_boss_profit(id)
	if not self.data.attribute[id] or not self.data.attribute[id].fixdrop then return {} end
	return config:change_cost_num(self.data.attribute[id].fixdrop)
end


return _M