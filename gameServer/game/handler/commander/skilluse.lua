-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.commander"

local _M = function(role,data)
	if not data.skillid or type(data.skillid) ~= "number" then return 2 end
	
	local id = data.id or 101
	local commander = role.commanders:get(id)
	if not commander then return 400 end
	local canup = config:canuse_skill(commander,data.skillid)
	if not canup then return 401 end
	commander:skill_use(data.skillid)
	return 0
end

return _M
