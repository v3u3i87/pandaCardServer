-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not role.alliancegirl:can_tryst() then return 101 end
	role.alliancegirl:tryst()
	return 0
end

return _M
