-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local pass  = role.arena:check_refresh()
	if not pass then return 2102 end
	local anana_ranks =  role.arena:refresh()
	return 0,{data = anana_ranks}
end
return _M
