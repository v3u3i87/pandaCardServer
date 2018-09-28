-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local math_random = require "include.random"
local table_insert = table.insert
local math_floor = math.floor
local rankMgr = require "manager.rankMgr"
local min =math.min
local swapHashKV = require "include.swaphashkv"


local _M = {}
_M.data = {
	rank = config.template.arena,
}
_M.arena_stage_max = 5
_M.arena_add_stage_interval_time = 3600 * 2
_M.arena_buy_refresh_max = 1
_M.arena_refresh_need_diamond = 50
_M.arena_refresh_add_stage = 5
_M.arena_id = 7 
_M.arean_object_num = 4
_M.arena_stage_time_max = 120
_M.arena_need_lv = 15

--战斗胜利：20w金币  30荣誉
--战斗失败：10w金币  15荣誉
function _M:stage_profit(win,num)
	local cost = {}
	if win == 1 then
		cost[config.resource.money] = 200000 * num
		cost[self.arena_id] = 30 * num
	else
		cost[config.resource.money] = 100000 * num
		cost[self.arena_id] = 15 * num
	end
	return cost
end

--自身排名-自身排名*rand（0.16-0.25）-2
--自身排名-自身排名*rand（0.06-0.15）-1
--自身排名-自身排名*rand（0.01-0.05）
--自身排名+自身排名*rand（0.01-0.09）+1
function _M:refresh(pos,pos_id)
	local ids ={}
	local id = math_floor(pos - pos * math_random(16,25) /100  -2 )
	table_insert(ids,id)
	id =  math_floor(pos - pos * math_random(6,15) /100 -1)
	table_insert(ids,id)
	id = math_floor(pos - pos * math_random(1,5) /100 )
	table_insert(ids,id)
	if pos ~= 20000  then
		id = min(20000,math_floor(pos + pos * math_random(1,9) /100 +1 ) )
		table_insert(ids,id)
	end
	
	local rank = rankMgr:get(config.rank_type.arena)
	if not rank then return false end
	local myrank = rank:get_obj_ranking(pos_id)
	local objs = {}
	for k,v in ipairs(ids) do
		if v >0 then
			local object ={}
			object.typ = 0
			object.id = 0
			object.name = ""
			object.lv = 0
			object.atk= 0
			object.pos =v
			local obj_data = rank:get_objs_from_pt_range(v,v+1)
			obj_data = swapHashKV(obj_data,"ar")
			local obj = obj_data[v]
			if not obj then object.typ = 1
			else 
				object.name = obj.name
				object.lv = obj.lev
				object.atk= obj.atk
				object.id= obj.id
			end
			table_insert(objs, object)
		end
	end

	return objs
end

function _M:beign_stage(id1,pos1, id2,pos2,typ)
	if typ ~= 1 then
		local rank = rankMgr:get(config.rank_type.arena)
		if not rank then return false end
		local find_rank2 = rank:get_obj_ranking(pos2)
	end
end


function _M:get_range_reward()
	local range = {}
	local profit ={}
	for k,v in ipairs(self.data.rank) do
		local lrang ={}
		table_insert(lrang,v.pm[1])
		table_insert(lrang,v.pm[2])
		table_insert(range,lrang)
		--[[2,150],[7,2000]]
		local profitone =  config:change_cost(v.rewards)
		table_insert(profit, profitone)
	end
	return range,profit
end

return _M