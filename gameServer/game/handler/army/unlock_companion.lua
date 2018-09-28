-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.army"

local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	if data.pos < 7 then return 706 end
	local pass, cost = role.army:check_unlock_companion_pos(data.pos)
	if pass then
		local en,diamond,cost = role:check_resource_num(cost)
		if not en then return 100 end
		role:consume_resource(cost)
		role.army:set_unlock_companion_pos(data.pos)
	else return 705 end
	return 0
end

return _M
