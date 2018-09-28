-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local floor = math.floor
local config = require "game.config"
local timetool = require "include.timetool"
local item_config = require "game.template.item"
local append_attributes = require "game.model.append_attributes"
local table_insert = table.insert
local cjson = require "include.cjson"


local _M = {}
_M.data = {
	base = config.template.commander,
	advance = config.template.commanderrank,
	skill = config.template.commanderskill,
	vehicle = config.template.vehicle,
	stage = config.template.stage,
	comcar = config.template.comcar,
	comcar_exp = config.template.comcarexp,
	comcar_star = config.template.comcarstar,
	comcar_strengthen = config.template.comcarstrengthen,
	comderskillconsume = config.template.comderskillconsume,
}
_M.car_level_id ={22119,22120,22121}
_M.commander_money_defind = 10000

function _M:canup_skill(commander,skillid)
	local lev = commander:get_skill_level(skillid)
	if not lev then return false end
	local skill_config = self.data.skill[skillid]
	if not skill_config then return false end
	local consume_config = self.data.comderskillconsume[skillid][lev]
	if not consume_config then return false end
	if consume_config.pos_req == 0 then 
		if commander:get_level() < consume_config.lev_req then return false end
	else
		local lev = commander:get_skill_level(consume_config.pos_req)
		if lev < consume_config.lev_req then return false end
	end
	return true
end

function _M:canuse_skill(commander,skillid)
	local use_time = commander:get_skill_use_time(skillid)
	local skill_config = self.data.skill[skillid]

	if not skill_config then return false end
	if 	timetool:now() - use_time <=	skill_config.skillcd then return false end
	return true
end

function _M:get_skill_up_cost(commander,skillid)
	local lev = commander:get_skill_level(skillid)
	local consume_config = self.data.comderskillconsume[skillid][lev]
	return {[config.resource.money] = consume_config.money}
end

function _M:get_max_mrank()
	return #self.data.advance
end

function _M:canup_mrank(commander)
	local lev = commander:get_mrank_lev()
	local maxlev = self:get_max_mrank()
	return lev < maxlev
end

function _M:get_mrank_up_cost(commander)
	local mr = commander:get_mrank_lev()
	if mr > #self.data.advance then return false end
	return config:change_cost(self.data.advance[mr].percost)
end

function _M:calc_mrankup_suc(commander)
	local mr = commander:get_mrank_lev()
	local mrn = commander:get_mrank_upcount() + 2
	local rank = self.data.advance[mr]
	local math_random = math.random
	local bless = math_random(rank.pervalue[1],rank.pervalue[2])
	local pro = 0
	if mrn > rank.successnum then
		return true,bless
	elseif mrn > rank.stage6_num then
		pro = rank.stage6_success
	elseif mrn > rank.stage5_num then
		pro = rank.stage5_success
	elseif mrn > rank.stage4_num then
		pro = rank.stage4_success
	elseif mrn > rank.stage3_num then
		pro = rank.stage3_success
	elseif mrn > rank.stage2_num then
		pro = rank.stage2_success
	elseif mrn > rank.stage1_num then
		pro = rank.stage1_success
	end
	local rand = math_random(0,10000)
	return rand < pro , bless
end

function _M:get_asicskill(commander_id)
	if not self.data.base[commander_id] then return {} end
	return self.data.base[commander_id].asicskill or {}
end

function _M:get_vehicleidkill(commander_id)
	local skillid ={}
	if not self.data.base[commander_id] then return {} end
	local vehicleid = self.data.base[commander_id].vehicleid or {}
	for i,v in ipairs(vehicleid) do
		local vehicle = self.data.vehicle[v]
		if vehicle then
			local commanderskillid = vehicle.commanderskillid
			table_insert(skillid, commanderskillid)
		end
	end
	return skillid
end

function _M:get_activeskill(commander_id)
	if not self.data.base[commander_id] then return {} end
	return self.data.base[commander_id].activeskill or {}
end

function _M:get_passiveskill(commander_id)
	if not self.data.base[commander_id] then return {} end
	return self.data.base[commander_id].passiveskill or {}
end

function _M:get_vehicleskill(vehicleid)
	if not self.data.vehicle[vehicleid] then return false end
	return self.data.vehicle[vehicleid].commanderskillid or false
end


function _M:get_vehicle(commander_id)
	if not self.data.base[commander_id] then return {} end
	return self.data.base[commander_id].vehicleid or {}
end



function _M:canuse_weapon(commander,weaponid)
	if not commander:get_role() then return false end
	if not commander:get_weapon_level(weaponid) then return false end
	local wc = self.data.vehicle[weaponid].activationcondition
	if commander:get_level() < wc[1] then return false end
	local stage_id = commander:get_role().base:get_stage()
	if not self.data.stage[stage_id] then return false end
	--local wins = commander:get_role().base:get_wins()
	--if wins == 0 then wins = 1 end
	--if wins > #self.data.stage[stage_id] then wins = #self.data.stage[stage_id] end
	if self.data.stage[stage_id][2].uniqueid < wc[2] then return false end
	return true
end

function _M:canup_weapon(commander,weaponid)
	local lev = commander:get_weapon_level(weaponid)
	local maxlev = commander:get_level() * 2

	return true
end

function _M:get_weapon_up_cost(commander,weaponid)

	return {[config.resource.money] = 100}
end

function _M:get_quality(id)
	return self.data.comcar[id].quality
end

function _M:can_active(commander,id)
	local comcar = commander:get_car(id)
	if comcar then return false end
	return true
end

function _M:get_active_cost(commander,id)
	if not self.data.comcar[id] then return false end
	local cid = self.data.comcar[id].synnum[1]
	local cnum = self.data.comcar[id].synnum[2]
	return {[cid] = cnum},cid
end

function _M:is_car_level_id(id)
	local find =false
	for i,v in ipairs(self.car_level_id) do
		if v == id then
			find =true
			break
		end
	end
	return find
end

function _M:can_car_level_up(commander,id,uid)
	local car = commander:get_car(id)
	if not car then return false end
	local lv = car:get_level()
	local q = self:get_quality(id)
	if not self.data.comcar_exp[ lv+1]['exp'..q] then return false end
	local add_exp = 0
	local new_uid ={}
	for i,v in ipairs(self.car_level_id) do
	
		if uid[v] then 
			add_exp = add_exp + item_config:get_value(v) * uid[v]

			new_uid[v] = uid[v]
		end
	end


	return car:get("exp") + add_exp >= self.data.comcar_exp[ lv+1]['exp'..q] ,add_exp,new_uid
end

function _M:get_car_level_up_cost(commander,id,cost)
	local car = commander:get_car(id)
	local lv = car:get_level()
	cost[config.resource.money]	= self.data.comcar_exp[ lv+1].cost * self.commander_money_defind
	return cost
end

function _M:get_car_level_up_exp(id,lv)
	local q = self:get_quality(id)
	if not self.data.comcar_exp[lv +1]['exp'..q] then return false end
	return self.data.comcar_exp[lv +1]['exp'..q]
end

function _M:get_car_max_level()
	return #self.data.comcar_exp
end

function _M:can_car_star_up(commander,id)
	local car = commander:get_car(id)
	if not car then return false end
	local star = car:get_star()
	local q = self:get_quality(id)
	local lv = car:get_level()
	if not self.data.comcar_star[star+1][q] then return false end
	return self.data.comcar_star[star+1][q].lv <= lv
end

function _M:get_car_star_up_cost(commander,id)
	local cost ={}
	local car = commander:get_car(id)
	local star = car:get_star()
	local q = self:get_quality(id)
	local cid = self.data.comcar_star[star+1][q].cost[1]
	local cnum = self.data.comcar_star[star+1][q].cost[2]
	cost[cid] = cnum
	cost[config.resource.money] = self.data.comcar_star[star+1][q].gold * self.commander_money_defind
	local a,cid2 = self:get_active_cost(commander,id)
	cost[cid2] = self.data.comcar_star[star+1][q].card
	return cost
end

function _M:can_car_strengthen(commander,id)
	local car = commander:get_car(id)
	if not car then return false end
	local strengthen = car:get_strengthen()
	if not self.data.comcar_strengthen[strengthen +1] then return false end
	return true
end

function _M:get_car_strengthen_cost(commander,id)
	local cost ={}
	local car = commander:get_car(id)
	local strengthen = car:get_strengthen()
	local cid = self.data.comcar_strengthen[strengthen+1].cost[1]
	local cnum = self.data.comcar_strengthen[strengthen+1].cost[2]
	cost[cid] = cnum
	cost[config.resource.money] = self.data.comcar_strengthen[strengthen+1].gold * self.commander_money_defind
	return cost
end

function _M:get_full_attributes(id,attrs)
	local rs = {
		base = {},
		rate = {}
	}
	--[[for i,v in pairs(attrs.s) do
		local consume_config = self.data.comderskillconsume[i][v]
		--ngx.log(ngx.ERR,"i:",i," v:",v," consume_config:",cjson.encode(consume_config))
		if consume_config and consume_config.data and consume_config.data[2] then
			if consume_config.data[2] == 1 then
				append_attributes(rs.base,consume_config.data,v)
			elseif consume_config.data[2] == 2 then
				append_attributes(rs.rate,consume_config.data,v)
			end
		end
	end]]--
	--[[local skill = self.data.skill
	for i,v in pairs(attrs.s) do
		if skill[i].skilltype == 1 then
			local p = skill[i].promotevalue_base
			if p[2] ==  1 then
				append_attributes(rs.base,{p},v)
			else
				append_attributes(rs.rate,{{p[1],1,p[2]}},v)
			end
		end
	end]]--
	--ngx.log(ngx.ERR,"rs:",cjson.encode(rs))
	return rs
end

function _M:get_choose_commander(id)
	local p="ZHG00" .. id
	return p,self.data.base[p].vehicleid[1]
end

return _M