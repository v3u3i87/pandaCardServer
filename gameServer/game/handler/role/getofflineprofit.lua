-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not role.extend:has_offline_profit() then return 303 end
	local profit = role.extend:receive_offline_profit()
	if profit then role:push("resource.get",profit) end
	return 0
end

return _M
