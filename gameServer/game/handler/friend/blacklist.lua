-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local CFriend = require "game.model.role.friend"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	if data.opt ~= 1 and data.opt ~=2 then return 1209 end
	local frole = nil
	if data.typ == 1 then
		frole = roleMgr:get_role(data.id)
		if not frole then return 1200 end
	end
	local list = {}
	if data.opt == 1 then--1.加入２移除
		if frole then list = role.friends:check_blacklist_add_one(data.id) 
		else list = role.friends:check_blacklist_add_all() end
	elseif  data.opt == 2 then
		if frole then list = role.friends:check_blacklist_remove_one(data.id) 
		else list = role.friends:check_blacklist_remove_all() end
	end
	if not list or #list == 0 then return 1211 end
	if data.opt == 1 then role.friends:set_blacklist_add(list)
	elseif data.opt == 2 then role.friends:set_blacklist_remove(list) end
	return 0
end

return _M