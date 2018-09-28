-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local pass =  role.resource:can_inspire(data.pos,data.num)
	if not pass then return 2602 end
	local cost = role.resource:get_inspire_cost(data.pos,data.num)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local num = role.resource:set_inspire()
	return 0,{num =num}
end
return _M
