-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"


local _M = function(role,data)
	if not data.id or data.id <= 0 then return 2 end
	local frole = roleMgr:get_role(data.id)
	if not frole then return 2900 end
	local battle = frole:get_battle_info()
	return 0,{data = battle}
end

return _M
