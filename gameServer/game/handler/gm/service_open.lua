-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not role.isgm then return 2 end
	local global = require "game.global"
	global:open()
	return 0
end

return _M
