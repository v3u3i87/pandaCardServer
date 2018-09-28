-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	local pass = role.alliancegirl:can_get_reward(data.id)
	if not pass then return 2301 end
	local profit = role.alliancegirl:get_reward(data.id)

	role:gain_resource(profit)
	return 0,{data = profit}
end
return _M
