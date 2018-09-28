-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	local pass =  role.explore:check_adventure(data.pos)
	if not pass then return 2003 end
	local pass = role.explore:remove_adventure(data.pos,true)
	if not pass then return 2000 end
	return 0
end
return _M
