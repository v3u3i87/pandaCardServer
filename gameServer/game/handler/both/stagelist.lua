-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	local stage_lists =  role.both:stage_list()
	return 0,{data = stage_lists}
end
return _M
