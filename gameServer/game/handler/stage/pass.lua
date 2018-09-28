-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.stage"
local base_config = require "game.config"
local task_config = require "game.template.task"
local _M = function(role,data)
	if not data.id or not data.lev then return 2 end
	if data.isboss and data.isboss == 1 then
		data.isboss = true
	else
		data.isboss = false
	end
	if not config:exist_level(data.id,data.isboss) then return 2 end
	if data.win and data.win == 1 then
		data.win = true
	else
		data.win = false
	end

	if not data.win then return 0 end
		
	local profit = config:get_profit(data.id,data.isboss,role.base:get_wins())
	local mx = 1.0
	if role.base:has_month_card() then
		mx = mx + 0.1
	end
	if role.base:has_life_card() then
		mx = mx + 0.1
	end
	local floor = math.floor
	profit[base_config.resource.money] = floor(profit[base_config.resource.money] * mx)


	role:gain_resource(profit)
	
	if data.isboss then
		role.base:cross_stage()
	else
		role.base:win_stage_fight()
	end
	role.tasklist:trigger(task_config.trigger_type.stage_max)
	return 0
end

return _M
