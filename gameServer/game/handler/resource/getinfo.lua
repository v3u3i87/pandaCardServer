-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local resourceMgr = require "game.model.resourceMgr"
local _M = function(role,data)
	list = resourceMgr:get_all_stage_info()
	return 0,{data=list}
end
return _M
