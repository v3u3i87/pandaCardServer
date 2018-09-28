-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.commander"

local _M = function(role,data)
	if not data.cid or type(data.cid) ~= "number" then return 2 end
	local id = data.id or 101
	local commander = role.commanders:get(id)
	if not commander then return 400 end
	
	local canup = commander:can_use(data.cid)
	if not canup then return 101 end

	commander:use_car(data.cid)
	return 0
end

return _M
