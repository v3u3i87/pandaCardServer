-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local task_config = require "game.template.task"

local _M = function(role,data)
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	local pass = role.shop:can_refresh(data.typ)
	if not pass then return 2701 end
	local pass,cost = role.shop:get_refresh_cost(data.typ)
	if not pass then return 100 end
	role:consume_resource(cost)
	local list = role.shop:refresh(data.typ)
	role.tasklist:trigger(task_config.trigger_type.shop_refresh)

	return 0,{data=list}
end
return _M
