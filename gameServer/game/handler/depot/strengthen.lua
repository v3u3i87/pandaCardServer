-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.item"
local task_config = require "game.template.task"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.num then data.num = 1 end
	if not data.num or type(data.num) ~= "number" then return 2 end
	local item = role.depot:get(data.id)
	if not item then return 2 end

	local canup = config:can_strengthen(item,data.num,role:get_level())
	if not canup then return 101 end
	
	local cost,exp = config:get_strengthen_cost(item,data.num,role)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then
		if data.usediamond ~= 1 or role.base:get_diamond() < diamond then return 100 end
	end
	role.tasklist:trigger(task_config.trigger_type.depot_strengthen_great_lev)


	role:consume_resource(cost)
	item:strengthen(data.num,exp,cost)
	return 0
end

return _M
