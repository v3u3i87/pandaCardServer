-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if data.id <=0 or data.id > 6 then return 1900 end
	local pass =  role.boss:can_buy_item(data.id)
	if not pass then return 1907 end
	local cost = role.boss:get_can_buy_cost(data.id)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit = role.boss:buy_item(data.id)
	role:gain_resource(profit)
	return 0
end
return _M
