-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	local pass =  role.arena:can_begin_stage(data.pos)
	if not pass then return 2104 end
	role.arena:beign_stage(data.pos)
	return 0,{data = anana_ranks}
end
return _M
