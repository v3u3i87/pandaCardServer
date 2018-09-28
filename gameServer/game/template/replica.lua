-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local math_random = require "include.random"
local table_insert = table.insert



local _M = {}
_M.data = {
	boss = config.template.counterboss,
	stage = config.template.counterstage,
	bosstype1 = 0,
	bosstype2 = 0,
}

_M.replica_l_cout_max = 5
_M.replica_h_cout_max = 5
_M.replica_reset_hour = 3
_M.replica_energy_max = 100
_M.replica_stage_cost_energy = 10
_M.replica_add_energy_interval = 360
_M.replica_h_reset_count_max = 1
_M.replica_h_reset_add_diamond = 20
_M.replica_l_need_lv = 40
_M.replica_h_need_lv = 50
_M.replica_box_need_star ={4,8,12}
_M.replica_refresh_boss_hour ={6,12,18}


--[[id	数字	表id
fs	数组	[0,0,0,0]1已首杀
n	数字	次数
g	数字	1已领取通关奖励
ps	数组	[0,0,0,0]1已过关
--]]

--[[
	id	数字	表id
fs	数组	[0,0,0,0]1已首杀
ns	数组	[5,5,5,5]剩余次数
ss	数组	[0,0,0,0]星级
gl	数字  通关奖励等级0~3
rn	数组	[0,0,0,0]已重置次数
ps	数组	[0,0,0,0]1已过关
--]]

function _M:create_list(typ)
	local lists ={}
	for i,v in pairs(self.data.stage) do
		if typ == 1 and v.id < 100 then
			local list ={}
			list.id = v.id
			list.fs = {0,0,0,0}
			list.ps = {0,0,0,0}
			list.g =0
			table_insert(lists,list)
		elseif typ == 2 and v.id > 100 then
			local list ={}
			list.id = v.id
			list.fs = {0,0,0,0}
			list.ps = {0,0,0,0}
			list.ns = {self.replica_l_cout_max,self.replica_l_cout_max,self.replica_l_cout_max,self.replica_l_cout_max}
			list.ss ={0,0,0,0}
			list.gl = 0
			list.rn ={0,0,0,0}
			table_insert(lists,list)
		end
	end
	return lists
end

function _M:create_l_list()
	return self:create_list(1)
end
function _M:create_h_list()
	return self:create_list(2)
end

function _M:get_stage_profit(f,id,stage,win,num)
	local profit={}
	local profit_add ={}
	if win == 1 then
		local profit_f = {}
		if f == 1 and self.data.stage[id].friitem  then
			for i=1,#self.data.stage[id].friitem,2 do
				local lid = self.data.stage[id].friitem[i]
				local num = self.data.stage[id].friitem[i+1]
				profit[lid] = num
				profit_f[lid] = num
			end
		end

		for i=1,num do
			local profit_one = {}
			if i == 1 and f == 1 then profit_one = profit_f end
			local rd = math_random(1,#self.data.stage[id].secitem)
			local num1 = math_random(self.data.stage[id].secitem[rd][2],  self.data.stage[id].secitem[rd][3] )
			local id = self.data.stage[id].secitem[rd][1]
			profit[id] = (profit[id] or 0 ) + num1
			profit_one[id] =num1
			table_insert(profit_add,profit_one)
		end

	end
	return profit,profit_add,f
end

function _M:check_hlist_box(hlist_data,id,pos)
	local star = 0
	for i,v in ipairs(hlist_data.ss) do
		star = star + v 
	end
	if star < self.replica_box_need_star[pos] then return false end
	return true
end

function _M:check_llist_box(llist_data,id,pos)
	local find = false
	if not llist_data.ps then return true end
	for i,v in ipairs(llist_data.ps) do
		if v == 0 then 
			find = true
			break
		end
	end
	if find then return false end
	return true
end

function _M:get_box_profit(id,pos)
	if id < 100 then
		return config:change_cost(self.data.stage[id].chest)
	else
		return config:change_cost_arry(self.data.stage[id].chest[pos])
	end
end

function _M:get_reset_cost( )
	return {[config.resource.diamond] = self.replica_h_reset_add_diamond }
end

function _M:get_boss_profit(id)
	local rd = math_random(1,#self.data.boss[id].drop)
	local num = math_random(self.data.boss[id].drop[rd][2],  self.data.boss[id].drop[rd][3] )
	local idn = self.data.boss[id].drop[rd][1]
	return {[idn] = num}
end

function _M:get_bosstype1_data()
	if not self.bosstype1 then
		self.bosstype1  = 0
		for k,v in pairs(self.data.boss) do
			if v.id >0 and v.id <100 then self.bosstype1 = self.bosstype1 +1 end
		end
	end
	return self.bosstype1
end

function _M:get_bosstype2_data()
	if not self.bosstype2 then
		self.bosstype2  = 0
		for k,v in pairs(self.data.boss) do
			if v.id >100  then self.bosstype2 = self.bosstype2 +1 end
		end
	end
	return self.bosstype2
end


function _M:boss_refresh(typ)
	local id = 0
	local rd = 0
	if typ == 1 then
		rd = math_random(1,self:get_bosstype1_data())
		id = self.data.boss[rd].id
	else
		rd = math_random(1,self:get_bosstype2_data())
		id = self.data.boss[rd + 100].id
	end
	return id
end

function _M:get_boss_consume(id)
	return tonumber(self.data.boss[id].consume)
end

return _M