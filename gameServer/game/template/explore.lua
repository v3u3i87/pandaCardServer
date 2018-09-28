-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local timetool = require "include.timetool"

local math_random = math.random
local math_ceil = math.ceil
local math_min = math.min
local table_insert = table.insert

local _M = {}
_M.data = {
	explore = config.template.explore,
	event = config.template.exploreadven,
	box = config.template.explorechest,
	rand ={},
	box_rand ={},
	explore_rand = {},
}

_M.explore_find_adventure_pro = 20  -- 20
_M.explore_energy_free_max = 10
_M.explore_add_energy_interval = 600
_M.explore_auto_need_vip = 5
_M.explore_buy_max = 2
_M.explore_buy_count_need_diamond = 20
_M.explore_buy_count_add_energy = 5
_M.explore_get_box_first = 20
_M.explore_get_box_second = 50
_M.explore_open_box_count = 3 
_M.explore_speed_max = 50
_M.explore_list_max =12
_M.explore_find_boss_pro = 20  --15
_M.explore_use_prop_id = 9
_M.explore_speed_count = 50
_M.explore_typ1_adventure_time = 7200
_M.explore_typ2_adventure_time = 1800
_M.explore_typ3_adventure_time = 3600
_M.explore_boss_need_level = 60


function _M:can_beging(pos,lv,stage)
	--if lv < self.data.explore[pos].oplv then return false end
	--if stage < self.data.explore[pos].opst then return false end
	return true
end

function _M:get_beging_cost(num)
	return { [self.explore_use_prop_id] = num or 1}
end

function _M:get_explore_profit(pos,num)
	local rand_data= self:get_explore_rand(pos)
	local idx = self:get_rand_index(rand_data.n,rand_data.pro,2)
	if idx == 0 then return false end
	local inum = rand_data.pro[idx][1] or 1
	local profit = config:change_cost_arry(self.data.explore[pos].item1,inum)
	local r1 = math_random(1,config.pro_define)
	if r1 < rand_data.extra_n then
		local idx1 = self:get_rand_index(rand_data.extra_n,rand_data.extra,3)
		if idx1 == 0 then return false end
		local id = rand_data.extra[idx1][1]
		local num = rand_data.extra[idx1][2]
		profit[id] = (profit[id] or 0) + num
	end
	return profit
end

function _M:get_explore_rand(id)
	if not self.data.explore_rand[id] then
		self.data.explore_rand[id] = {}
		self.data.explore_rand[id].n = 0
		self.data.explore_rand[id].pro = self.data.explore[id].pro
		for i,v in pairs(self.data.explore_rand[id].pro) do
			self.data.explore_rand[id].n = self.data.explore_rand[id].n + v[2]
		end
		self.data.explore_rand[id].extra_n = 0
		self.data.explore_rand[id].extra = self.data.explore[id].extra
		for i,v in pairs(self.data.explore_rand[id].extra) do
			self.data.explore_rand[id].extra_n = self.data.explore_rand[id].extra_n + v[3]
		end
	end
	return self.data.explore_rand[id]
end



function _M:get_random(id)
	if not self.data.rand[id] then
		self.data.rand[id] = {}
		self.data.rand[id].n = 0
		self.data.rand[id].type = self.data.explore[id].adventure
		for i,v in pairs(self.data.rand[id].type) do
			self.data.rand[id].n = self.data.rand[id].n + v[2]
		end
		self.data.rand[id].fight_n = 0
		self.data.rand[id].fight = self.data.explore[id].adventurefight
		for i,v in pairs(self.data.rand[id].fight) do
			self.data.rand[id].fight_n = self.data.rand[id].fight_n + v[1]
		end
		self.data.rand[id].shop_n = 0
		self.data.rand[id].shop = self.data.explore[id].adventureshop
		for i,v in pairs(self.data.rand[id].shop) do
			self.data.rand[id].shop_n = self.data.rand[id].shop_n + v[1]
		end
		self.data.rand[id].box_n = 0
		self.data.rand[id].box = self.data.explore[id].adventurechest
		for i,v in pairs(self.data.rand[id].box) do
			self.data.rand[id].box_n = self.data.rand[id].box_n + v[1]
		end

	end
	return self.data.rand[id]
end

--pro .第几位为机率
function _M:get_rand_index(num,data,pro)
	local r1 = math_random(1,num)
	local idx = 0
	local index = pro or 1
	for i,v in ipairs(data) do
		if r1 < v[index] then
			idx = i
			break;
		end
		r1 = r1 - v[index]
	end
	return idx
end

function _M:adventure_one(id)
	local rand_data= self:get_random(id)
	local r = math_random(1,rand_data.n)
	local idx = self:get_rand_index(rand_data.n,rand_data.type,2)
	if idx == 0 then return false end
	local pos_id =0
	local typ = rand_data.type[idx][1]
	if typ == 1 then
		local idx1 = self:get_rand_index(rand_data.fight_n,rand_data.fight)
		if idx1 == 0 then return false end
		local r1 = math_random(1,#rand_data.fight[idx1][2])
		pos_id = rand_data.fight[idx1][2][r1]
	elseif typ == 2 then
		local idx1 = self:get_rand_index(rand_data.shop_n,rand_data.shop)
		if idx1 == 0 then return false end
		local r1 = math_random(1,#rand_data.shop[idx1][2])
		pos_id = rand_data.shop[idx1][2][r1]
	elseif typ == 3 then
		local idx1 = self:get_rand_index(rand_data.box_n,rand_data.box)
		if idx1 == 0 then return false end
		local r1 = math_random(1,#rand_data.box[idx1][2])
		pos_id = rand_data.box[idx1][2][r1]
	end

	local adventure_one ={}
	adventure_one.typ = typ
	adventure_one.id = pos_id
	adventure_one.bt = timetool:now()
	adventure_one.sid = 0
	adventure_one.n = 0
	if typ == 1 then
		local rd = math_random(1,#self.data.event[pos_id].stage)
		adventure_one.sid = self.data.event[pos_id].stage[rd]
	end

	return true,adventure_one
end

function _M:create_adventure(pos,num,list_num)
	local adventure ={}
	local count = 0
	for i=1,num do
		local rd = math_random(1,100)
		if rd < self.explore_find_adventure_pro then
			local pass,adventure_one = self:adventure_one(pos)
			if pass then 
				table_insert(adventure,adventure_one)
				count = count +1
			end
			if list_num + count >= self.explore_list_max then break end
		end
	end
	return adventure
end

function _M:get_adventure_profit(pos,typ,step)
	local id = 0
	local num = 0
	if typ == 1 or typ == 2 then
		local rd = math_random(1,#self.data.event[pos].item)
		id = self.data.event[pos].item[rd][1]
		num = self.data.event[pos].item[rd][2]
	elseif typ == 3 then
		if step == 1 then 
			id = self.data.event[pos].item[1][1]
			num = self.data.event[pos].item[1][2]
		elseif step == 2 then 
			id = self.data.event[pos].item[2][1]
			num = self.data.event[pos].item[2][2]
		elseif step == 3 then 
			id = self.data.event[pos].item[3][1]
			num = self.data.event[pos].item[3][2]
		end
	end
	return  { [id] = num}
end

function _M:get_buy_shop_cost(pos)
	local id = 0
	local num = 0
	id = self.data.event[pos].consume[1]
	num = self.data.event[pos].consume[3]
	return  { [id] = num}
end

function _M:get_heavenbox_cost(count)
	local diamond = 0
	if count == 0 then diamond = 0
	elseif count == 1 then diamond = self.explore_get_box_first
	elseif count == 2 then diamond = self.explore_get_box_second end
	return diamond
end

function _M:get_addnum_cost(count)
	return {[config.resource.diamond] = self.explore_buy_count_need_diamond}
end

function _M:get_sp_box_profit(pos)
	local rd = math_random(1,#self.data.explore[pos].accumulated)
	local id = self.data.explore[pos].accumulated[rd][1]
	local num = self.data.explore[pos].accumulated[rd][2]
	return  { [id] = num}
end

function _M:get_box_cost(typ)
	if type(self.data.box[typ].goods) ~= "table" then  return false end
	local id = self.data.box[typ].goods[1]
	local num = self.data.box[typ].goods[2]
	return  { [id] = num}
end

--[[
低级单次 min(80,20 + (step /3) *5)
低级十次 min(800,200 + (step) *15)
单次 step +1
十次 step +2


高级单次 min(150,75 + (step ) *15)
高级十次 min(1500,750 + (step) *125)
单次 step +1
十次 step +2

低级 .高级眇数分开计算
--]]
function _M:get_box_cost_diamond(typ,step)
	local diamond =0
	if typ == 1 then diamond = math_min(80, 20 + math_ceil(step /3) * 5)
	elseif typ == 2 then diamond = math_min(800, 200 + math_ceil(step) * 15)
	elseif typ == 3 then diamond = math_min(150, 75 + math_ceil(step ) * 15)
	elseif typ == 4 then diamond = math_min(1500, 750 + math_ceil(step ) * 125) 
	end
	return {[config.resource.diamond] = diamond}
end


function _M:get_box_random(id)
	if not self.data.box_rand[id] then
		self.data.box_rand[id] = {}
		self.data.box_rand[id].n = 0
		self.data.box_rand[id].item = self.data.box[id].item
		for i,v in pairs(self.data.box_rand[id].item) do
			self.data.box_rand[id].n = self.data.box_rand[id].n + v[3]
		end
		self.data.box_rand[id].ten_n = 0
		if type(self.data.box[id].gtreasure) == "table" then
			self.data.box_rand[id].ten_item = self.data.box[id].gtreasure
			for i,v in pairs(self.data.box_rand[id].ten_item) do
				self.data.box_rand[id].ten_n = self.data.box_rand[id].ten_n + v[3]
			end
		end
	end
	return self.data.box_rand[id]
end

function _M:get_box_profit_one(typ,count)
	local data = self:get_box_random(typ).item
	local max = self:get_box_random(typ).n
	if type == 3 or typ ==4 then
		if count % 10 == 0 then 
			data = self:get_box_random(typ).ten_item
			max = self:get_box_random(typ).ten_n
		end
	end
	local idx1 = self:get_rand_index(max,data,3)
	if idx1 == 0 then return false end
	return   data[idx1][1]  , data[idx1][2] 	
end


function _M:get_box_profit(typ,hcount)
	local profit = {}
	local profitadd ={}
	local num = 1
	if typ == 2 or typ == 4 then num = 10 end
	for i=1,num do
		local id,num = self:get_box_profit_one(typ,hcount+i)
		profit[id] = (profit[id] or 0) + num
		table_insert(profitadd,{[id]=num})
	end 
	return profit,profitadd
end

return _M