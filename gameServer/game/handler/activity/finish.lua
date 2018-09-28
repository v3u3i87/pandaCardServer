-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id then return 2 end
	local task = role.activitylist:get(data.id)
	if not task then return 3000 end
	if not task:can_finish() then return 3002 end
	local pass,profit = role.activitylist:finish(task.id)
	if not pass then return 3003 end
	return 0,{data = profit}
end

return _M
