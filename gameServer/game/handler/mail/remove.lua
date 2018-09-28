-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id then return 2 end
	data.id = tonumber(data.id)
	local mail = role.mailbox:get(data.id)
	if not mail then return 1100 end
	if mail:has_attachment() then return 1103 end
	role.mailbox:remove(data.id)
	return 0
end

return _M