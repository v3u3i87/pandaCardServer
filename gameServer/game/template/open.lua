-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local cjson = require "include.cjson"

local _M = {}
_M.data = config.template.Interface

_M.need_level = {
	arena = 1,
	replica=2,
	both=3,

	arsenal = 6,

	soldier_awaken= 8,
	soldier_superevolve =9,
	army=10,
	soldier_evolve=11,
	soldier_break=12,
	research=13,
	research_high=14,
	reclaim=15,
	army_add_companion=16,
	battle_fast=17,
	explore_l = 18,
	explore_h = 19,

	rank =21,
	chat=22,
	friend=23,
	resource=24,
	boss_shop =25,
	boss=26,
	depot_forging=27,
	commander_car=28,
	replica_boss = 29,
	shop_type_9 = 30,
	arena_shop =31,
}

_M.need_vip={
	stage_boss = 32,
	arsenal_challenge_num = 33,
	explore_begin_num =34,

	resource_stage_num =37, 

	army_unlock_companion = 40,
}


function _M:get(id)
	return self.data[id]
end

function _M:check_level(role,id)
	if not role or not self.data[id] then return false end
	return role:get_level() >= self.data[id].level	
end

function _M:check_vip(role,id)
	if not role or not self.data[id] then return false end
	return role:get_vip_level() >= self.data[id].vip	
end

function _M:check_vip_by_vip(vip,id)
	if not self.data[id] then return false end
	return vip >= self.data[id].vip	
end


return _M