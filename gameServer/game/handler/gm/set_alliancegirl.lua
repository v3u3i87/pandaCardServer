-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"
local task_config = require "game.template.task"

local _M = function(role,data)
	local mr = gm_check(role,data)
	if not mr or not data.typ then return 2 end
	data.typ = tonumber(data.typ) or 1
	data.value = tonumber(data.value) or 1
	if data.typ == 1 then mr.alliancegirl:set("normal",data.value)
	elseif data.typ == 2 then mr.alliancegirl:set("special",data.value) end
	mr:push_update()
	return 0
end

return _M
