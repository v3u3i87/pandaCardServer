-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local vip_config = require "game.template.vip"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	local pass =  role.base:check_buy_vip_item(data.id)
	if not pass then return 3201 end
	local pass,cost = vip_config:get_buy_vip_item_cost(data.id)
	if not pass then return 3202 end
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit = vip_config:get_vip_item(data.id)
	role:gain_resource(profit)
	role.base:set_buy_vip_item(data.id)

	return 0,{data = profit}
end
return _M
