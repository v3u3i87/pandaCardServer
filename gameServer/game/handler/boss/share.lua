-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	if data.typ ~= 1 and data.typ ~= 2 then return 1901 end
	if role.boss:is_boss_die() then return 1903 end
	local pass,role_list,boss_info = role.boss:get_share_list(data.id,data.typ)
	if not pass then return 1908 end
	for i,role in ipairs(role_list) do
		role.boss:add_boss_list(boss_info)
	end
	return 0 
end
return _M
