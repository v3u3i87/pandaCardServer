-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	if not data.num or type(data.num) ~= "number" then return 2 end
	local item_config = require "game.template.item"
	if not role.depot:check_depot_full(item_config.type.equipment) then return 602 end
	local pass =  role.explore:can_beging(data.pos,data.num)
	if not pass then return 2000 end
	local pass,cost,num = role.explore:get_beging_cost(data.pos,data.num)
	if not pass then return 2002 end
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit = role.explore:beign_explore(data.pos,data.num)
	role:gain_resource(profit)
	role.explore:cost_explore_num(num)
	return 0,{data = profit}
end
return _M
