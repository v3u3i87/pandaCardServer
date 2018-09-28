-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.commander"

local _M = function(role,data)
	data.id = data.id or 101
	data.weaponid = data.weaponid or ""
	
	local commander = role.commanders:get(data.id)
	if not commander then return 400 end
	if not commander:get_weapon_level(data.weaponid) then return 2 end
	
	local canup = config:canup_weapon(commander,data.weaponid)
	if not canup then return 101 end
	
	local cost = config:get_weapon_up_cost(commander,data.weaponid)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then return 100 end
	
	role:consume_resource(cost)
	commander:weapon_up(data.weaponid)
	
	return 0
end

return _M
