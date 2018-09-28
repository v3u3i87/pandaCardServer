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
	commander:change_weapon(data.weaponid)
	
	return 0
end

return _M
