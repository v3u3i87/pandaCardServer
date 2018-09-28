-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602

local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	local item_config = require "game.template.item"
	if not role.depot:check_depot_full(item_config.type.equipment) then return 602 end
	local pass =  role.explore:can_sp_box(data.pos)
	if not pass then return 2002 end
	local profit = role.explore:get_sp_box_profit(data.pos)
	role:gain_resource(profit)
	return 0,{data = profit}
end
return _M
