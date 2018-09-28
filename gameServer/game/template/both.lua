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
local roleMgr = require "manager.roleMgr"
local max= math.max



local _M = {}
_M.data = {
	unions = config.template.duizhanjuntuan,
	rank   = config.template.duizhanrank,
	reward =config.template.duizhanreward,
}
_M.both_need_level =45
_M.both_begin_hour = 10
_M.both_end_hour = 21
_M.both_rank_reward_hour = 22
_M.both_unions_begin1_time = 12*3600
_M.both_unions_end1_time = 12*3600 +1800
_M.both_unions_begin2_time = 18*3600 +1800
_M.both_unions_end2_time = 19*3600
_M.both_defind_points		= 200
_M.both_stage_add_points		= 10
_M.both_defind_unions_points		= 100
_M.both_stage_add_unions_points		= 20
_M.both_list_count = 3
_M.both_record_count = 20
_M.both_list_random = 20  --自身积分相差不超过20%的对手
_M.both_max_anger = 150
_M.both_stage_win_add_anger = 15
_M.both_reward_by_anger = 5 -- 每点怒气能够提供0.5%的额外收益；
_M.both_cost_anger_time = 3600
_M.both_cost_anger_count = 10
_M.both_profit_cost = 20  --玩家每被掠夺一次，则下次被掠夺的收益降低20%， 胜利一次增加40%   最少保留20%；
_M.both_profit_min = 20
_M.both_stage_fail_add_money = 1	--1%的钱
_M.both_defind_profit_pro = 100		--收益率20~100(奖励 * ap/100)
_M.both_min_profit_pro = 20

_M.both_add_stage_interval	= 1800
_M.both_stage_max = 6
_M.both_add_stage_need_diamond = 30


function _M:stage_profit(win,level,ap)
	local profit ={}
	local money =0
	local exp =0
	local index = 0
	for i,v in ipairs(self.data.reward) do
		if 	level >=v.level[1] and level <= v.level[2] then 
			index = i
			profit = config:change_cost(v.reward)
			break
		end
	end
	if index == 0 then profit = config:change_cost(self.data.reward[1].reward) end
	if win ~= 1 then
		--失败了 1%的钱,不得经验
		local profit_buf ={}
		for i,v in ipairs(profit) do
			if i == config.resource.money then
			--table_insert(profit_buf,{[config.resource.money]  = math_floor(v /100) }) end
			profit_buf[config.resource.money] =  math_floor(v /100) end
		end
		profit = profit_buf
	end
	if profit[config.resource.money] then money = math_floor(profit[config.resource.money] * ap /100) end
	if profit[config.resource.exp] then exp = math_floor(profit[config.resource.exp] * ap /100) end
	profit[config.resource.money] = money
	profit[config.resource.exp] = exp
	return money,exp,profit
end

function _M:is_find(data,id)
	local find = false
	for i,v in ipairs(data) do
		if v == id then 
			find = true
			break
		end
	end
	return find
end


function _M:refresh_list(id,num)
	local rank = rankMgr:get(config.rank_type.both)
	if not rank then return {} end
	if not num then num = 0 end
	local r = rank:get_obj_ranking(id)
	local rank_ids = rank:get_range_objs(1,10)
	if #rank_ids <3 then
		rank = rankMgr:get(config.rank_type.fight_point)
		r = rank:get_obj_ranking(id)
	end

	--排名最近的10个人中取3个
	--自己主动输一场  取排名的下限+3
	local r_min = max(1,r - 5 + num *3)
	if r_min == r then r_min = r_min + 1 end
	local r_max = r + 5 + num *3
	local ids ={}
	for i=1,10 do
		local fid = math_random(r_min,r_max)
		if fid == r then 
			if r_min < 5 then fid = math_random( max(1,r_min-2),r_max-2) 
			else fid = math_random(r_min+1,r_max+1) end
		end
		if not self:is_find(ids,fid) and fid ~= r then table_insert(ids,fid) end
		if #ids >=3 then break end
	end
	local objs = {}
	for k,v in ipairs(ids) do
		local object ={}
		local data = rank:get_range_objs(v,v)
		if #data <= 0  then data =  rank:get_range_objs(r+1,r+3) end
		if #data <= 0  then data =  rank:get_range_objs(max(r-3,1),max(1,r-1) ) end
		if #data >0 then
			object.id = data[1].id
			object.name = data[1].name
			if object.name and #object.name >1 then
				object.gh = data[1].un
				object.ap = config.both_defind_profit_pro
				object.p  = "1"
				local frole = roleMgr:get_role(object.id)
				if frole then 
					object.ap = frole.both:get_both_ap() 
					object.p= frole.commanders:get_p()
					object.money,object.exp = self:stage_profit(1,frole:get_level(),object.ap)
				end
				table_insert(objs, object)
			end
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
		table_insert(lrang,v.rank[1])
		table_insert(lrang,v.rank[2])
		table_insert(range,lrang)
		local profitone =  config:change_cost(v.reward)
		table_insert(profit, profitone)
	end
	return range,profit
end

return _M