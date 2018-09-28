-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "login.server"
local cjson = require "include.cjson"

local _M = function(args)
	if not args then return false,"no params1" end
	local notify = config:get_notify()
	return ngx.say(cjson.encode({content = notify}) )
end

return _M