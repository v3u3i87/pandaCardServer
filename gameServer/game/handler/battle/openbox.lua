-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.base"

local _M = function(role,data)
	local box = role:open_supplybox()
	if not box then return 801 end
	role:push("resource.get",box)
	return 0
end

return _M
