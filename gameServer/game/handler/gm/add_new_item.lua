-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"

local _M = function(role,data)
	data.id = tonumber(data.id)
	data.num = data.num or 1
	data.num = tonumber(data.num)
	local mr = gm_check(role,data)
	if not mr or not data.id then return 2 end
	mr:gain(data.id,data.num)
	mr:push_update()
	return 0
end

return _M
