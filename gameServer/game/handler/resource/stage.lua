-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.win or type(data.win) ~= "number" then return 2 end
	local profit ={}
	local profitadd ={}
	if data.typ and  data.typ == 1 then
		local pass =  role.resource:can_stage_all()
		if not pass then return 2600 end
		profit,profitadd = role.resource:stage_all()
	else
		local pass =  role.resource:can_stage(data.id)
		if not pass then return 2600 end
		profit = role.resource:stage(data.id,data.win)
		role.resource:set_stage_end(data.id,data.win)
		profitadd = profit
	end
	role:gain_resource(profitadd)
	return 0,{data = profit}
end
return _M
