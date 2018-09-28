-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.item"
local cjson = require "include.cjson"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not config:get(data.id) then return 2 end
	local canuse = config:can_use(data.id)
	if not canuse then return 101 end
	
	data.num = tonumber(data.num) or 1
	data.pos = tonumber(data.pos) or 1
	local item_num = role.knapsack:get(data.id)
	if item_num < data.num then return 100 end
	role.knapsack:use(data.id,data.num)
	local profit,addprofie = config:item_use(data.id,data.num,data.pos)
	role:gain_resource(profit)
	return 0,{data = addprofie}
end

return _M
