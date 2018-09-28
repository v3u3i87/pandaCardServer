-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local _M = function(role,data)
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	if not data.num then data.num = 1 end
	local pass =  role.base:can_change_money(data.typ,data.num)
	if not pass then return 2000 end
	local cost = role.base:get_change_money_cost(data.typ,data.num)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit = role.base:get_change_money_profit(data.num)
	role:gain_resource(profit)
	return 0,{data = profit}
end
return _M
