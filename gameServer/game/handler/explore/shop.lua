-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	local item_config = require "game.template.item"
	if not role.depot:check_depot_full(item_config.type.equipment) then return 602 end
	local pass =  role.explore:check_adventure(data.pos,2)
	if not pass then return 2003 end
	local cost = role.explore:get_buy_shop_cost(data.pos)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit = role.explore:buy_shop(data.pos)
	role:gain_resource(profit)
	role.explore:remove_adventure(data.pos)
	return 0,{data = profit}
end
return _M
