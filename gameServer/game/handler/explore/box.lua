-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local _M = function(role,data)
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	local item_config = require "game.template.item"
	if not role.depot:check_depot_full(item_config.type.equipment) then return 602 end
	local pass =  role.explore:can_box(data.typ)
	if not pass then return 2000 end
	local cost = role.explore:get_box_cost(data.typ)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit,addprofie = role.explore:get_box_profit(data.typ)
	role:gain_resource(profit)
	role.explore:set_box_step(data.typ)
	return 0,{data = addprofie}
end
return _M
