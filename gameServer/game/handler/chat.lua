-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local open_config = require "game.template.open"


local _M = function(role,data)
	if not data.content or type(data.content) ~= "string" then return 2 end
	if #data.content < 1 then return 2 end

	if not open_config:check_level(role,open_config.need_level.chat) then return 101 end

	data.channel = data.channel or -1
	
	if type(data.channel) == "string" then
		data.channel = roleMgr:get_role_id(data.channel)
		if not data.channel then return 2000 end
	end
	
	data.channel = tonumber(data.channel)
	if data.channel < - 3 then data.channel = 0 end
	
	if data.channel > 0 then
		if data.channel == role.id then return 2001 end
		local torole = roleMgr:get_role_in_cache(data.channel)
		if not torole or not torole:is_online() then return 2000 end
		torole:push_chat(role,data.content)
	else
		roleMgr:send_chat_msg(role,data.channel,data.content)
	end

	return 0
end

return _M
