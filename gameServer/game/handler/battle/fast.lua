-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.base"

local _M = function(role,data)
	if not role.base:can_fight_fast() then return 800 end
	local cost = config:get_fast_fight_cost(role.base:get_fast_fight_count() + 1)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then return 100 end
	
	local profit = role.base:fast_fight()
	role:consume_resource(cost)
	
	return 0,{data=profit}
end

return _M
