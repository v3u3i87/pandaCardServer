-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"
local task_config = require "game.template.task"

local _M = function(role,data)
	local mr = gm_check(role,data)
	if not mr or not data.stage then return 2 end
	data.stage = tonumber(data.stage) or 1
	local stage_buff = "STAGE"
	if data.stage< 10 then stage_buff = stage_buff .. "00" .. data.stage
	elseif data.stage >=10 and  data.stage <100 then stage_buff = stage_buff .. "0" ..data.stage
	else stage_buff = stage_buff ..data.stage end
	mr.base:set("stage",stage_buff)
	mr:push_update()
	return 0
end

return _M
