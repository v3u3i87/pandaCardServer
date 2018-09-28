-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.commander"
local open_config = require "game.template.open"

local _M = function(role,data)
	if not data.cid or type(data.cid) ~= "number" then return 2 end
	local id = data.id or 101
	if not open_config:check_level(role,open_config.need_level.commander_car) then return 101 end

	local commander = role.commanders:get(id)
	if not commander then return 400 end
	
	local canup = config:can_active(commander,data.cid)
	if not canup then return 101 end
	
	local cost = config:get_active_cost(commander,data.cid)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then
		if data.usediamond ~= 1 or role.base:get_diamond() < diamond then return 100 end
	end
	role:consume_resource(cost)
	commander:active_car(data.cid,cost)
	return 0
end

return _M
