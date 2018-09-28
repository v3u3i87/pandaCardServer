-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local pass,cost = role.research:check_lottery_cost(2)
	if not pass then return 100 end
	role:consume_resource(cost)
	local profit =  role.research:lottery_high_one()
	role:gain_resource(profit)
	return 0,{data=profit}
end
return _M
