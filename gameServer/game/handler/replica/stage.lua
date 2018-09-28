-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.stage or type(data.stage) ~= "number" then return 2 end
	if not data.win or type(data.win) ~= "number" then return 2 end
	if not data.star or type(data.star) ~= "number" then return 2 end
	if not data.num or type(data.num) ~= "number" then return 2 end
	if data.star < 0 or data.star > 3 then return 2 end
	if data.num <0 then return 2 end

	if not role.replica:check_stage(data.id,data.stage,data.num) then return 2201 end
	local profit,profitadd,f = role.replica:get_stage_profit(data.id,data.stage,data.win,data.num)

	role:gain_resource(profit)
	role.replica:set_stage(data.id,data.stage,data.win,data.star,data.num,f)
	return 0,{data=profitadd}
end
return _M
