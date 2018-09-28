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

local _M = {}
_M.data = {
	rank = config.template.recordrank,
}
_M.record_reward_item_id = 5

function _M:get_range_reward()
	local range = {}
	local profit ={}
	for k,v in pairs(self.data.rank) do
		table_insert(range,{v.rank[1],v.rank[2]})
		table_insert(profit,{[v.item[1]]=v.item[2]})
	end
	return range,profit
end

function _M:get_record_reward(pos)
	if pos == 1 then return {[self.record_reward_item_id] = 3}
	elseif pos == 2 then return {[self.record_reward_item_id] = 2}
	elseif pos == 3 then return {[self.record_reward_item_id] = 1}
	end
end

return _M