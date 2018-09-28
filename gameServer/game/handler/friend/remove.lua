-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id then return 2 end
	data.id = tonumber(data.id)
	local frole = role.friends:get(data.id)
	if not frole then return 1202 end
	role.friends:remove(data.id)
	return 0
end

return _M