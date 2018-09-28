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
	if not data.opt or type(data.opt) ~= "number" then return 2 end
	if data.opt ~= 1 and data.opt ~=2 then return 1209 end
	local frole = nil
	if data.typ == 1 then
		frole = roleMgr:get_role(data.id)
		if not frole then return 1200 end
	end
	local list = {}
	if frole then list = role.friends:check_apply_one(data.id) 
	else list = role.friends:check_apply_all() end
	if not list  or #list == 0 then return 1210 end
	if data.opt == 1 then 
		role.friends:set_apply_add(list)
		for id,friend in pairs(list) do
			if friend and frole then
				local fr = CFriend:new(nil,{info=role:get_simple_info(),typ=2})
				frole.friends:append(role:get_id(),fr)
			end
		end
	elseif data.opt == 2 then role.friends:set_apply_remove(list) end
	return 0
end

return _M