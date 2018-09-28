-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local gm_check = require "game.handler.gm.gm_check"

local _M = function(role,data)
	--local cjson = require "include.cjson"
	--ngx.log(ngx.ERR,cjson.encode(data))
	local mr = gm_check(role,data)
	if not mr or not data.id then return 2 end
	data.id = tonumber(data.id)
	if not mr.base:pay_item(data.id) then return 1 end
	return 0
end

return _M
