-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local math_ceil = math.ceil
local table_insert = table.insert
local mergeProfit = require "game.model.merge_profit"
local append_attributes = require "game.model.append_attributes"
local math_random = math.random

local cjson = require "include.cjson"
local _M = {}
_M.data = {
	equipment = config.template.accessory,
	upgrade = config.template.upgrade,
	items = config.template.item,
	frag = config.template.armyfrag,
	combine = config.template.combine,

	equipjinglian = config.template.equipjinglian,
	equipqianghua = config.template.equipqianghua,
	equipduanzao = config.template.equipduanzao,
	accjinglian = config.template.accjinglian,
	accqianghua = config.template.accqianghua,
	
	attributeid = config.template.attributeid,
	equipshuxing = config.template.equipshuxing,

	goodsfrag = config.template.goodsfrag,
	itemuse = config.template.itemuse,
	rand_item_use = {},
	item_maintype_quality = {},
}

_M.type = {
	unknown = 0,
	virtual = 1,
	soldier = 2,
	soldierfrag = 3,
	equipment = 4,
	accessory = 5,
	material = 6,
	property = 7,
	equipmentfrag = 8,
	accessoryfrag = 9,
	awaken = 10,
	soldierillustrated  = 11,
	box = 12,


	commander = 99,
}

_M.depot_equipment_max_num = 200
_M.depot_accessory_max_num = 200
_M.accqianghua_id1  =		22068	--紫色配饰强化石
_M.accqianghua_id2  =		22069	--橙色配饰强化石

_M.knapsack_max_num = 999
_M.refine_uids = {22011,22012,22013,22014}

_M.accqianghua_ids={22068,22069}

_M.reclaim_profit_itemid = {
	[_M.type.equipment] = 16,
	[_M.type.accessory] = 22070,
}
_M.reclaim_profit_num = {
	[_M.type.equipment] = {
		[1] = 5,
		[2] = 10,
		[3] = 20,
		[4] = 40,
		[5] = 80,
		[6] = 160,
	},
	[_M.type.accessory] = {
		[1] = 5,
		[2] = 10,
		[3] = 20,
		[4] = 40,
		[5] = 80,
		[6] = 160,
	}
}
_M.reclaim_highquality_equip_profit = {[19] = 120}


_M.MAXLVARMYMLEVEL = 160  --/士兵最大的等级
_M.MAXEQULEVEL = 320   --装备最大强化等级`
_M.MAXEQUREFINE = 50   --装备最大精炼等级
_M.MAXEQUFPRGE = 10   --装备最大锻造等级
_M.MAXACCLEVEL = 160   --配饰最大强化等级
_M.MAXACCREFINE = 20   --配饰最大精炼等级


function _M:__init()
	for k,v in pairs(self.data.items) do
		 self.data.item_maintype_quality[v.maintype] = self.data.item_maintype_quality[v.maintype] or {}
		 self.data.item_maintype_quality[v.maintype][v.quality] = self.data.item_maintype_quality[v.maintype][v.quality] or {}	
		 table_insert(self.data.item_maintype_quality[v.maintype][v.quality],k)
	end
end

function _M:get(id)
	return self.data.items[id]
end

function _M:get_type(id)
	local item = self:get(id)
	if not item then return self.type.unknown end
	return item.maintype
end

function _M:get_quality(id)
	local item = self:get(id)
	if not item then return 1 end
	return item.quality
end

function _M:get_value(id)
	local item = self:get(id)
	if not item then return 0 end
	return item.value or 0
end

function _M:get_equipment_position(id)
	if not self.data.equipment[id] then return 0 end
	return self.data.equipment[id].type
end

function _M:get_diamond_cost(id,p1,p2,p3)
	return 10
end

function _M:get_reclaim_profit(id)
	local item = self:get(id)
	if not item then return false end
	local t = self:get_type(id)
	local q = self:get_quality(id)
	local p = {}
	if self.reclaim_profit_itemid[t] then
		p[self.reclaim_profit_itemid[t]] = self.reclaim_profit_num[t][q]
	end
	if t == self.type.equipment and q == 6 then
		p = mergeProfit(p,self.reclaim_highquality_equip_profit)
	end
	return p
end

function _M:check_is_refine_id(id)
	local find =false
	for i,v in pairs(self.refine_uids) do
		if v == id then
			find = true
			break
		end
	end
	return find
end

function _M:can_refine(item,uid)
	local id = item:get_pid()
	local t = self:get_type(id)
	local lev = item:get_refine_lev()
	local quality = self:get_quality(id)
	if t == self.type.equipment then
		if lev +1 > self.MAXEQUREFINE  then return false end
		if not self.data.equipjinglian[lev+1]['exp'..quality] then return false end
	elseif t == self.type.accessory then
		if lev+1 > self.MAXACCREFINE   then return false end
		if not self.data.accjinglian[id][lev+1].cost then return false end
	end
	return true
end

function _M:get_refine_levexp(id,lev)
	if self:get_type(id) == self.type.equipment then
		return self.data.equipjinglian[lev]['exp'..self:get_quality(id)] or 0
	end
	return  0
end

function _M:get_refine_cost(item,uid)
	local exp = 0
	local id = item:get_pid()
	local cost = {}
	local t = self:get_type(id)
	local lev = item:get_refine_lev()
	local quality = self:get_quality(id)
	if t == self.type.equipment then
		cost = {[uid] = 1}
		exp = self:get_value(uid)
	elseif t == self.type.accessory then
		cost = config:change_cost(self.data.accjinglian[id][lev+1].cost)
	end
	--ngx.log(ngx.ERR,"exp:",exp, " exp_typ:",exp_typ ," lv:",lv)
	return	cost,exp
end

function _M:can_strengthen(item,num,lv)
	local id = item:get_pid()
	local t = self:get_type(id)
	local lev = item:get_strong_lev()
	if not lv then lv  = lev end
	local quality = self:get_quality(id)
	if t == self.type.equipment then
		for i=1,num do
			lev = lev +1
			if lev > self.MAXEQULEVEL then return false end
			if lev > lv * 2 then return false end
			if not self.data.equipqianghua[lev] or not self.data.equipqianghua[lev]['cost'..quality] then return false end
		end
	elseif t == self.type.accessory then
		for i=1,num do
			lev = lev +1
			if lev > self.MAXACCLEVEL  then return false end

			if lev > lv  then return false end
			if not self.data.accqianghua[lev] or not self.data.accqianghua[lev]['cost'..quality] then return false end
		end
	end
	return true
end

function _M:get_strengthen_cost(item,num,role)
	local id = item:get_pid()
	local cost ={}
	local addexp = -1
	local lv = 0
	local lev = item:get_strong_lev()
	local quality = self:get_quality(id)
	local t = self:get_type(id)
	if t == self.type.equipment then
		local moneyall = 0
		for i=1,num do
			local money = self.data.equipqianghua[lev]['cost'..quality]
			lev = lev +1
			moneyall = moneyall + money
		end
		cost = {[config.resource.money] = moneyall}
	elseif t == self.type.accessory then
		local need_exp = 0
		for i=1,num do
			local exp = self.data.accqianghua[lev]['cost'..quality]
			lev = lev +1
			need_exp = need_exp + exp
		end
		need_exp = need_exp - item:get_strong_exp()
		--ngx.log(ngx.ERR,"need_exp:",need_exp," lev:",lev," id:",id)
		--ngx.log(ngx.ERR," item:get_strong_exp():",item:get_strong_exp())
		if need_exp > 0 then
			local item_num1 = role.knapsack:get(self.accqianghua_id1)
			local item_num1_exp = 0
			if item_num1 and item_num1 > 0 then item_num1_exp = self:get_value(self.accqianghua_id1) * item_num1 end
			local item_need_num2 = 0
			local item_need_num1 = item_num1 or 0
			if need_exp > item_num1_exp  then
				item_need_num2 = math_ceil( (need_exp - item_num1_exp ) / self:get_value(self.accqianghua_id2) )
				addexp = item_need_num2 * self:get_value(self.accqianghua_id2)  -  need_exp
			else 
				item_need_num1 = math_ceil( (need_exp ) / self:get_value(self.accqianghua_id1) )
				addexp = item_need_num1 * self:get_value(self.accqianghua_id1)  -  need_exp
			end
			if item_need_num1 > 0 then cost[self.accqianghua_id1] = item_need_num1 end
			if item_need_num2 > 0 then cost[self.accqianghua_id2]  = item_need_num2 end
		end
	end
	return cost,addexp
end

function _M:can_forging(item)
	local id = item:get_pid()
	local lev = item:get_forging_lev()  +1
	if not self.data.equipduanzao[id] or not self.data.equipduanzao[id]['cost'..lev] then return false end
	return item:get_forging_lev() < 10 
end

function _M:get_forging_cost(item)
	local id = item:get_pid()
	local lev = item:get_forging_lev()  +1
	return config:change_cost(self.data.equipduanzao[id]['cost'..lev])
end

function _M:can_use(id)
	local item = self:get(id)
	if not item then return false end
	return item.use == 1
end


function _M:get_kanapsack_compose_cost(id,num,role)
	local cost = {}
	local data = self.data.goodsfrag[id] 
	if not data then return false end
	local num1 = role.knapsack:get_num(data.fragid)
	local allnum = data.usenum * num
	local num2 =0

	if allnum - num1 <= 0 then
		cost[data.fragid] = allnum
	elseif data.otherid and data.otherid > 0 and allnum -num1 >0  then
		cost[data.fragid] = num1
		cost[data.otherid] = allnum - num1
	else return false
	end
	return true,cost
end

function _M:can_compose(id)
	local frag = self.data.frag[id]
	if not frag then return false end
	return true,frag.armygoal,frag.armynum
end

function _M:get_compose_cost(id,num)
	local t = self:get_type(id)
	if t == self.type.awaken then
		local frag = self.data.combine[id]
		if not frag then return false end
		return true,config:change_cost_num(frag.material,num)
	else
	end
end

function _M:get_strengthenall_cost(pos,role)
	local list = role.army:get_equipment_list_by_pos(pos)
	local moneyall = role.base:get_money()
	local cost_money = 0
	for i,v in ipairs(list) do
		local item = role.depot:get(v)
		local lev = item:get_strong_lev()
		local quality = self:get_quality(id)
		local t = self:get_type(id)
		if t == self.type.equipment then
			if not self.data.equipqianghua[lev]['cost'..quality] then break end
			moneyall = moneyall - self.data.equipqianghua[lev]['cost'..quality]
			--if moneyall <= 0 then break 
			if moneyall >0 then
				item:strengthen(1)
				cost_money = cost_money + self.data.equipqianghua[lev]['cost'..quality]
			end
		end
	end
	return {[config.resource.money] = cost_money}
end

function _M:get_strengthen_cost(item,num,role)
	local id = item:get_pid()
	local cost ={}
	local addexp = -1
	local lv = 0
	local lev = item:get_strong_lev()
	local quality = self:get_quality(id)
	local t = self:get_type(id)
	if t == self.type.equipment then
		local moneyall = 0
		for i=1,num do
			local money = self.data.equipqianghua[lev]['cost'..quality]
			lev = lev +1
			moneyall = moneyall + money
		end
		cost = {[config.resource.money] = moneyall}
	elseif t == self.type.accessory then
		local need_exp = 0
		for i=1,num do
			local exp = self.data.accqianghua[lev]['cost'..quality]
			lev = lev +1
			need_exp = need_exp + exp
		end
		need_exp = need_exp - item:get_strong_exp()
		--ngx.log(ngx.ERR,"need_exp:",need_exp," lev:",lev," id:",id)
		--ngx.log(ngx.ERR," item:get_strong_exp():",item:get_strong_exp())
		if need_exp > 0 then
			local item_num1 = role.knapsack:get(self.accqianghua_id1)
			local item_num1_exp = 0
			if item_num1 and item_num1 > 0 then item_num1_exp = self:get_value(self.accqianghua_id1) * item_num1 end
			local item_need_num2 = 0
			local item_need_num1 = item_num1 or 0
			if need_exp > item_num1_exp  then
				item_need_num2 = math_ceil( (need_exp - item_num1_exp ) / self:get_value(self.accqianghua_id2) )
				addexp = item_need_num2 * self:get_value(self.accqianghua_id2)  -  need_exp
			else 
				item_need_num1 = math_ceil( (need_exp ) / self:get_value(self.accqianghua_id1) )
				addexp = item_need_num1 * self:get_value(self.accqianghua_id1)  -  need_exp
			end
			if item_need_num1 > 0 then cost[self.accqianghua_id1] = item_need_num1 end
			if item_need_num2 > 0 then cost[self.accqianghua_id2]  = item_need_num2 end
		end
	end
	return cost,addexp
end

function _M:get_full_attributes(id,attrs)
	local rs = {}
	local item = self:get(id)
	local shuxing = self.data.equipshuxing[id]
	if not item or not shuxing then return rs end
	
	append_attributes(rs,shuxing.attr_base)
	append_attributes(rs,shuxing.attr_add,attrs.s-1)
	append_attributes(rs,shuxing.re_attr_add,attrs.r)
	if item.maintype == self.type.equipment and self.data.equipduanzao[id] then
		local dz = self.data.equipduanzao[id].add * attrs.d
		local dza = {}
		for i=1,6 do
			dza[i] = {i,2,dz}
		end
		append_attributes(rs,dza)
	end
	return rs


end


function _M:get_type_quality_item(goodstype,quality,num,exception)
	local data =self.data.item_maintype_quality[goodstype][quality]
	if not data then return {} end
	if exception and #exception >0 then
		local data_buf = {}
		for k1,v1 in ipairs(data) do
			local find = false
			for k2,v2 in pairs(exception) do
				if v1 == v2 then
					find = true
					break
				end
			end
			if not find then table_insert(data_buf,v1) end
		end
		data = data_buf
	end
	local r1 = math_random(1,#data)
	--ngx.log(ngx.ERR,"goodstype:",goodstype," quality:",quality," num:",num," r1:",r1)
	return {  [data[r1]] =  num}
end

function _M:get_rand_item_use(id)
	if not self.data.rand_item_use[id] then
		self.data.rand_item_use[id] = {}
		self.data.rand_item_use[id].n = 0
		self.data.rand_item_use[id].goods = self.data.itemuse[id].goods or {}
		for i,v in pairs(self.data.rand_item_use[id].goods) do
			self.data.rand_item_use[id].n = self.data.rand_item_use[id].n + v[3]
		end

		self.data.rand_item_use[id].goodstype_n = 0
		self.data.rand_item_use[id].goodstype = self.data.itemuse[id].goodstype or {}
		for i,v in pairs(self.data.rand_item_use[id].goodstype) do
			self.data.rand_item_use[id].goodstype_n = self.data.rand_item_use[id].goodstype_n + v[1]
		end

		self.data.rand_item_use[id].quality_n = 0
		self.data.rand_item_use[id].quality = self.data.itemuse[id].quality or {}
		for i,v in pairs(self.data.rand_item_use[id].quality) do
			self.data.rand_item_use[id].quality_n = self.data.rand_item_use[id].quality_n + v[1]
		end
	end
	return self.data.rand_item_use[id]
end

function _M:rand_item_use(id)
	local rand_data = self:get_rand_item_use(id)
	local idx = config:get_rand_index(rand_data.n,rand_data.goods,3)
	if idx == 0 then return false end
	return {  [rand_data.goods[idx][1]] = rand_data.goods[idx][2]}
end

--[[
物品使用类型 type
1获得虚拟物品
2直接获得物品
3获得一类物品（按照获得物品品质）
4多个物品随机获得一种
5多物品可选择获得一种
6使用后跳转至其他界面
]]--

function _M:item_use_one(id,pos)
	local profitone = {}
	if not self.data.itemuse[id] then return {} end
	local type = self.data.itemuse[id].type
	if type == 1 or type == 2 then
		profitone = config:change_cost_num(self.data.itemuse[id].goods)
	elseif type == 3 then
		local rand_data = self:get_rand_item_use(id)
		local goodstype =self.data.itemuse[id].goodstype[ config:get_rand_index(rand_data.goodstype_n,rand_data.goodstype)][2]
		local quality = self.data.itemuse[id].quality[config:get_rand_index(rand_data.quality_n,rand_data.quality)][2]
		local num = self.data.itemuse[id].num[ math_random(self.data.itemuse[id].num[1],self.data.itemuse[id].num[2]) or 1 ]
		--ngx.log(ngx.ERR,"goodstype:",goodstype," quality:",quality," num:",num)
		local exception ={}
		if self.data.itemuse[id].exception then exception = self.data.itemuse[id].exception end
		profitone = self:get_type_quality_item(goodstype,quality,num,exception) or {}
	elseif type == 4 then
		profitone = self:rand_item_use(id) or {}
	elseif type == 5 then
		profitone = { [self.data.itemuse[id].goods[pos][1]  ] = self.data.itemuse[id].goods[pos][2] }
	end
	return  profitone
end

function _M:item_use(id,count,pos)
	local profitadd ={}
	local profit ={}
	for i=1,count do
		local profitone = self:item_use_one(id,pos)
		table_insert(profitadd,profitone)
		for k,v in pairs(profitone) do
			profit[k] =(profit[k] or 0 ) + v 
		end
	end
	return profit,profitadd
end

return _M