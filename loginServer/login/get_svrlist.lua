-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "login.server"
local cjson = require "include.cjson"
local _M = function(args)
	if not args then return false,"no params1" end
	local server_list = config:get_serlist()
	return ngx.say(cjson.encode({s_serverIp = server_list}) )
end

return _M