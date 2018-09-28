-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.num then data.num = 1 end
	local pass =  role.boss:can_buy_challenge(data.num)
	if not pass then return 1906 end
	local pass,cost = role.boss:buy_challenge(data.num)
	if not pass then return 101 end
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.boss:add_challenge_count(data.num)
	return 0
end
return _M
