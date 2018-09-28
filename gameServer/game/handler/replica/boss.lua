-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	if not data.win or type(data.win) ~= "number" then return 2 end

	if not role.replica:check_boss(data.pos) then return 2201 end
	local profit = role.replica:get_boss_profit(data.pos,data.win)

	role:gain_resource(profit)
	role.replica:set_boss(data.pos,data.win)
	return 0,{data=profit}
end
return _M
