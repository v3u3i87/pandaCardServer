-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local generalMgr = require "game.model.general"
local config = require "game.template.soldier"

local _M = function(role,data)
	if not data.soldier_id then return 2 end
	if not config:get(data.soldier_id) then return 500 end
	return 0,{data = generalMgr:get_soldier_info(data.soldier_id)}
end

return _M
