-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local pass =  role.explore:can_addnum()
	if not pass then return 2004 end
	local cost = role.explore:get_addnum_cost()
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.explore:addnum()
	return 0
end
return _M
