-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local countMgr = require "game.model.countMgr"

local _M = function(role,data)
	data.id = data.id or 1
	data.id = tonumber(data.id)
	data.num = data.num or 1
	data.num = tonumber(data.num)
	countMgr:set_type_count(data.id,data.num)
	return 0
end

return _M
