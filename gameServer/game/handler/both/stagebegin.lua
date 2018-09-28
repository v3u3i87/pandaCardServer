-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	local pass =  role.both:can_stage(data.id)
	if not pass then return 2402 end
	role.both:set_begin_stage(data.id)
	return 0
end
return _M
