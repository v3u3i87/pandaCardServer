-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local base = require "game.template.base"
local config = require "game.config"
local table_sort = table.sort

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	local frole = nil
	if data.typ == 1 then
		frole = roleMgr:get_role(data.id)
		if not frole then return 1200 end
	end
	local list = {}
	local num = base:get_friend_receive_count(role)
	if num <= 0 then return  1206 end
	if frole then
		list = role.friends:check_receive_one(data.id) 
	else
		list = role.friends:check_receive_all()
	end
	if not list or #list == 0 then return 1204 end
	local count = #list
	if count > num then
		table_sort(list, base:friend_comps() )
		count = num
	end

	local profit ={}
	profit[config.resource.diamond]  = config.give_diamond * (count)
	role:gain_resource(profit)
	role.friends:set_receive(list,2,count)
	role.base:add_receive_count(count)
	return 0
end

return _M