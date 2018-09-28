-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"

local _M = function(role,data)
	local mr = gm_check(role,data)
	if not mr or not data.commanderid or not data.skillid or not data.skilllev then return 2 end
	local commander = mr.commanders:get(data.commanderid)
	if not commander then return 2 end
	local s = commander:get('s')
	data.skillid = tonumber(data.skillid)
	if not s[data.skillid] then return 2 end
	s[data.skillid] = data.skilllev
	commander:set('s',s)
	mr:push_update()
	return 0
end

return _M
