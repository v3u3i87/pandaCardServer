-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local pass =  role.arena:can_buycount(data.pos,data.num)
	if not pass then return 2103 end
	local cost = role.arena:get_buycount_cost(data.pos,data.num)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.arena:add_count()
	return 0
end
return _M
