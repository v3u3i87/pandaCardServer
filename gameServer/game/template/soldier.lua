-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local append_attributes = require "game.model.append_attributes"

local _M = {}
_M.data = {
	base = config.template.hero,
	rank = config.template.armyrank,
	upgrade = config.template.upgrade,
	promote = config.template.armypromote,
	super = config.template.armyreform,
	break_con = config.template.armybreak,
	awake = config.template.armyawake,
}
_M.badge_time = 23 * 3600
_M.reclaim_profit_itemid = 17
_M.reclaim_profit_num = {
	[1] = 5,
	[2] = 10,
	[3] = 20,
	[4] = 40,
	[5] = 80,
	[6] = 160,
}
_M.hero_type = {
	hero = 1,
	mbreak = 2,
	gz = 3,
}
_M.hero_armyquality = {
	white = 1,
	xx = 2,
	dd = 3,
	jj = 4,
	orange = 5,
	red = 6,
}

function _M:get(id)
	return self.data.base[id]
end

function _M:get_reclaim_profit(id,num)
	local soldier = self:get(id)
	if not soldier then return false end

	return {[self.reclaim_profit_itemid]=self.reclaim_profit_num[soldier.armyquality or 1] * num}
end																			

function _M:canup(soldier)
	local lev = soldier:get_level()
	return lev < #self.data.upgrade
end

function _M:get_level_up_cost(soldier)
	local lev = soldier:get_level()
	local money = self.data.upgrade[lev].amycost
	return {[config.resource.money] = money}
end

function _M:canevolve(soldier)
	local pid = soldier:get_pid()
	if not self.data.promote[pid] then return false end
	local q = soldier:get_quality()
	if not self.data.promote[pid][q+1] then return false end
	local lev = soldier:get_level()
	if lev < self.data.promote[pid][q+1].armylvlimit then return false end
	return true
end

function _M:get_evolve_cost(soldier)
	local pid = soldier:get_pid()
	local q = soldier:get_quality()
	if not self.data.promote[pid] or not self.data.promote[pid][q+1] then return false end
	return config:change_cost(self.data.promote[pid][q+1].cost)
end

function _M:cansuperevolve(soldier)
	local pid = soldier:get_pid()
	if not self.data.base[pid] then return false end
	return self.data.base[pid].reform
end

function _M:get_superevolve_cost(soldier)
	local sq = soldier:get_superquality()
	local id = soldier:get_pid()
	return config:change_cost(self.data.super[id][sq+1].material)
end

function _M:calc_evolve_suc(soldier)
	local q = soldier:get_quality()
	local qn = soldier:get_quality_upcount() + 2
	local rank = self.data.rank[q]
	local math_random = math.random
	local bless = math_random(rank.pervalue[1],rank.pervalue[2])
	local pro = 0
	if qn > rank.successnum then
		return true,bless
	elseif qn > rank.stage6_num then
		pro = rank.stage6_success
	elseif qn > rank.stage5_num then
		pro = rank.stage5_success
	elseif qn > rank.stage4_num then
		pro = rank.stage4_success
	elseif qn > rank.stage3_num then
		pro = rank.stage3_success
	elseif qn > rank.stage2_num then
		pro = rank.stage2_success
	elseif qn > rank.stage1_num then
		pro = rank.stage1_success
	end
	local rand = math_random(0,10000)
	return rand < pro , bless
end

function _M:get_full_attributes(id,attrs)
	local rs = {}
	local soldier = self:get(id)
	local shuxing = self.data.base[id]
	if not soldier or not shuxing then return rs end
	if attrs.m == 1 then
		local m_id = self.data.base[id].reform
		shuxing = self.data.base[m_id]
		if not shuxing then return rs end
	end
	append_attributes(rs,shuxing.base)
	append_attributes(rs,shuxing.add,attrs.l-1)
	
	--[[local rate = {}
	local promote = self.data.promote[id]
	if promote and promote[attrs.q] then
		local dz = promote[attrs.q].addattributerate - 1
		local dza = {}
		for i=1,6 do
			dza[i] = {i,2,dz}
		end
		append_attributes(rs,dza)

		if promote[attrs.q].promote_value[2] == 1 then
			append_attributes(rs,promote[attrs.q].promote_value[2],1)
		elseif promote[attrs.q].promote_value[2] == 2 then
			append_attributes(rate,promote[attrs.q].promote_value[2],1)
		end
	end
	for name,num in pairs(rate) do
		if rs[name] then rs[name] = rs[name] * (1+num/10000) end
	end]]--
	local promote = self.data.promote[id]
	if promote and promote[attrs.q] then
		local dz = promote[attrs.q].addattributerate - 1
		local dza = {}
		for i=1,6 do
			dza[i] = {i,2,dz}
		end
		append_attributes(rs,dza)
	end
	return rs
end

function _M:canbreak(soldier)
	local pid = soldier:get_pid()
	if not self.data.break_con[pid] then return false end
	local lev = soldier:get_level()
	if lev < self.data.break_con[pid].armylvlimit then return false end
	return true
end

function _M:get_break_cost(soldier)
	local pid = soldier:get_pid()
	local mr = soldier:get_mrank()
	if not self.data.break_con[pid]  then return false end
	return config:change_cost(self.data.break_con[pid].cost)
end

function _M:canwear(soldier,pos)
	local w = soldier:get_awaken_level()
	if not self.data.awake[w +1] then return false end
	if soldier:get_pos_equip(pos) >0 then return false end
	return true
end

function _M:get_wear_cost(soldier,pos)
	local w = soldier:get_awaken_level()
	if not self.data.awake[w +1] or not self.data.awake[w+1].equcost then return false end
	return {[ self.data.awake[w +1].equcost[pos] ] = 1 } ,self.data.awake[w +1].equcost[pos]
end

function _M:canawaken(soldier)
	local w = soldier:get_awaken_level()
	if not self.data.awake[w +1] then return false end
	return soldier:can_awaken()
end

function _M:get_awaken_cost(soldier)
	local w = soldier:get_awaken_level()
	if not self.data.awake[w+1]  then return false end
	return config:change_cost(self.data.awake[w+1].otcost)
end

function _M:get_initid(id)
	if not self.data.base[id] or not self.data.base[id].initid then return 0 end
	return self.data.base[id] and self.data.base[id].initid > 0  and self.data.base[id].initid or id
end

function _M:get_herotype(id)
	return self.data.base[id].herotype or self.hero_type.hero
end

function _M:get_armyquality(id)
	return self.data.base[id].armyquality or 1
end

function _M:is_breakid(id)
	if not self.data.base[id] or not self.data.base[id].breakid then return false end
	return self.data.base[id].breakid  > 0
end

return _M