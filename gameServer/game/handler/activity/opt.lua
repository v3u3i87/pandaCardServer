-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.task"
local _M = function(role,data)
	if not data.id or not data.typ then return 2 end
	if not data.pos then data.pos = 0 end
	if not data.num then data.num = 1 end
	local task = role.activitylist:get(data.id)
	if not task then return 3000 end
	local pass,cost = config:get_cost(data.id,data.num)
	if not pass then return 3004 end

	if data.typ == 1 then

	end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then return 100 end
	role:consume_resource(cost)
	task:trigger(data.num)
	if config:is_end(data.id,task.data.g)  then --or not task:can_finish()
		task:trigger(0-data.num)
		return 3002 
	end
	local pass,profit = role.activitylist:finish(task.id,data.pos,data.num)
	if not pass then return 3003 end
	return 0,{data = profit}
end
return _M
