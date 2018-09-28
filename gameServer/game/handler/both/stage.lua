-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.win or type(data.win) ~= "number" then return 2 end
	local pass =  role.both:can_stage(data.id,true)
	if not pass then return 2402 end
	local profit = role.both:stage(data.id,data.win)
	role:gain_resource(profit)
	local both_lists =  role.both:refresh_list()
	return 0,{data = profit}
end
return _M
