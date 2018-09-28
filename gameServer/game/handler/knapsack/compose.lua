-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.item"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not config:get(data.id) then return 2 end
	
	if not data.num then data.num = 1 end
	local pass,cost = config:get_kanapsack_compose_cost(data.id,data.num,role)
	if not pass then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then	 return 100 end
	role:consume_resource(cost)
	role:gain_resource({ [data.id] =  data.num} )
	
	return 0,{data={ [data.id] =  data.num} }
end

return _M
