-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local timetool = require "include.timetool"
local resourceMgr = require "game.model.resourceMgr"
local table_insert = table.insert
local max= math.max

local _M = {}
_M.data = {
	reward = config.template.plunderstage,
}
_M.resource_need_level =60
_M.resource_begin_time = 10 *3600
_M.resource_end_time = 23 *3600
_M.resource_boss_begin_time1 = 12 *3600 + 40 *60
_M.resource_boss_end_time1 = 13 *3600
_M.resource_boss_begin_time2 = 18 *3600 
_M.resource_boss_end_time2 = 18 *3600 + 20* 60
_M.resource_reset_time1 =9*3600
_M.resource_reset_time2 =17*3600
_M.resource_inspire_need_diamond={30,50,100,300,1000,2000}
_M.resource_all_need_level = 70
_M.resource_all_need_vip = 7
_M.resource_inspire_max = 6


function _M:get_stage_type(id)
	if not self.data.reward[id] then return false end
	return self.data.reward[id].type
end

function _M:get_stage_need_step(id )
	if not self.data.reward[id] then return false end
	return self.data.reward[id].start
end


function _M:can_stage_begin(id)
	local zero_time = timetool:get_hour_time(0)
	local ltime = timetool:now()
	local ctime = ltime - zero_time
	if not self.data.reward[id] then return false end
	if self.data.reward[id].type == 1 then
		if ctime < self.resource_begin_time or  ctime > self.resource_end_time then return false end
	elseif self.data.reward[id].type == 2 then
		local pass =false
		if ctime >= self.resource_boss_begin_time1 and ctime <= self.resource_boss_end_time1 then pass =true
		elseif ctime >= self.resource_boss_begin_time2 and ctime <= self.resource_boss_end_time2 then pass =true
		end
		if pass and resourceMgr:is_stage(id) then return true
		else return false end
	end
	return true
end

function _M:set_stage_begin(id)
	resourceMgr:set_stage_state(id,1)
end

function _M:set_stage_end(id)
	resourceMgr:set_stage_state(id,0)
end

function _M:stage(id,win,role_id)
	local profit = {}
	if win == 1 and self.data.reward[id].type == 1 then
		profit = config:change_cost(self.data.reward[id].reward)
	elseif win == 1 and self.data.reward[id].type == 2 then
		resourceMgr:set_stage_state(id,0,role_id)
	end
	return profit
end

function _M:stage_all(step,stepmax)
	local profit = {}
	local profitadd = {}
	for i,v in ipairs(self.data.reward) do
		if v.id > step and v.id <= stepmax then
			local profitone = config:change_cost(v.reward)
			table_insert(profit,profitone)
			for id,num in pairs(profitone) do
				profitadd[id] = (profitadd[id]  or 0) + num
			end
			
		end
	end
	return profit,profitadd
end

return _M