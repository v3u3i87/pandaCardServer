-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	local pass =  role.resource:can_stage_begin(data.id)
	if not pass then return 2600 end
	role.resource:set_stage_begin(data.id)
	return 0
end
return _M
