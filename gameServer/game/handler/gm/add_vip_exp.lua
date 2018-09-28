-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"

local _M = function(role,data)
	local mr = gm_check(role,data)
	if not mr or not data.exp then return 2 end
	data.exp = tonumber(data.exp) or 1
	mr.base:append_vip_exp(data.exp)
	return 0
end

return _M
