-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"

local _M = function(role,data)
	if not role.isgm then return false end
	if not data.uid and not data.uname then return false end
	if not data.uid then
		data.uid = roleMgr:get_role_id(data.uname)
	end
	return roleMgr:get_role(data.uid)
end

return _M
