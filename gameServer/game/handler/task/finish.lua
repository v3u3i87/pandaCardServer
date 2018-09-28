-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id then return 2 end
	local task = role.tasklist:get(data.id)
	if not task then return 1000 end
	if not task:can_finish() then return 1002 end
	local pass,profit = role.tasklist:finish(task.id)
	if not pass then return 1003 end
	return 0,{data = profit}
end

return _M
