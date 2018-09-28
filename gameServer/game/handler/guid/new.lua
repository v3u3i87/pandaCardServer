-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.nid then return 2 end
	role.guid:set_nid(data.nid)
	return 0
end

return _M
