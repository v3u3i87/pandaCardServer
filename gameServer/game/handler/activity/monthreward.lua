-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local pass = role.base:can_month_reward()
	if not pass then return 3001 end
	local cost = role.base:get_month_reward_cost()
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then return 100 end
	role:consume_resource(cost)
	local profit = role.base:get_month_reward_profit()
	role:gain_resource(profit)
	role.base:add_month_reward()
	return 0,{data = profit}
end
return _M
