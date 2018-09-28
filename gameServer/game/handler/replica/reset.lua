-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.pos or type(data.pos) ~= "number" then return 2 end

	local pass,cost =  role.replica:can_reset(data.id ,data.pos )
	if not pass then return 2205 end
	local cost = role.replica:get_reset_cost(cost)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.replica:set_reset(data.id ,data.pos )
	return 0
end
return _M
