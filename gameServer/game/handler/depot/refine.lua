-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local  config= require "game.template.item"
local task_config = require "game.template.task"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.uid and data.typ == 2 then
		for i,v in pairs(config.refine_uids) do
			if role.knapsack:get(v) then 
				data.uid = v
				break;
			end
		end
		--if not data.uid then return 100 end
	end
	if data.uid >0 and not config:check_is_refine_id(data.uid) then return 2 end

	local item = role.depot:get(data.id)
	if not item then return 2 end
	
	local canup = config:can_refine(item,data.uid)
	if not canup then return 101 end
	
	local cost,exp = config:get_refine_cost(item,data.uid)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then
		if data.usediamond ~= 1 or role.base:get_diamond() < diamond then return 100 end
	end
	role:consume_resource(cost)
	item:refine(exp,cost)
	role.tasklist:trigger(task_config.trigger_type.depot_refine_great_lev)

	return 0
end

return _M
