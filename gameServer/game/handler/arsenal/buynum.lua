-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.num then data.num = 1 end
	local pass = role.arsenal:can_buy_num(data.num)
	if not pass then return 1702 end
	local cost = role.arsenal:get_buy_cost(data.num)
	if cost then
		local en,diamond,cost = role:check_resource_num(cost)
		if not en then return 100 end
		role.arsenal:add_buy_num(data.num)
		role:consume_resource(cost)
	end
	return 0
end
return _M
