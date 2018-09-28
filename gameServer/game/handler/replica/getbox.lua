-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	if data.pos <=0 or data.pos > 3 then return 2 end
	local pass =  role.replica:can_get_box(data.id,data.pos)
	if not pass then return 2204 end
	local profit = role.replica:get_box_profit(data.id,data.pos)
	role:gain_resource(profit)

	role.replica:set_box(data.id,data.pos)
	return 0,{data=profit}
end
return _M
