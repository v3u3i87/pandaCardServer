-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"
local task_config = require "game.template.task"

local _M = function(role,data)
	local mr = gm_check(role,data)
	if not mr or not data.level then return 2 end
	data.level = tonumber(data.level) or 1
	mr.base:set("lev",data.level)
	mr:on_level_up()
	mr:push_update()
	
	mr.tasklist:trigger(task_config.trigger_type.commander_maxlev,data.level)

	return 0
end

return _M
