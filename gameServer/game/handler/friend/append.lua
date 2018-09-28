-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local CFriend = require "game.model.role.friend"
local base = require "game.template.base"

local _M = function(role,data)
	if not data.id then return 2 end
	if type(data.id) == "string" then
		data.id = roleMgr:get_role_id(data.id)
		if not data.id then return 1200 end
	end
	local num = base:get_friend_append_count(role)
	if num <= 0 then return 1207 end
	data.id = tonumber(data.id)
	local frole = roleMgr:get_role(data.id)
	if not frole then return 1200 end
	if role.friends:is_friend(data.id) then return 1201 end
	
	--已在对面好友
	if frole.friends:is_friend(role:get_id()) then
		local fr = CFriend:new(nil,{info=frole:get_simple_info(),typ = 2})
		role.friends:append(fr:get_id(),fr)
	else
		local fr = CFriend:new(nil,{info=role:get_simple_info()})
		frole.friends:append(fr:get_id(),fr)
	end
	return 0
end

return _M