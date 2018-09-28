-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if data.id <= 0 or data.id >9 then return 1700 end
	local pass = role.arsenal:can_get_box(data.id)
	if not pass then return 1703 end
	local profit = role.arsenal:get_box(data.id)
	role:gain_resource(profit)
	role.arsenal:get_box_end(data.id)
	return 0,{data=profit}
end
return _M
