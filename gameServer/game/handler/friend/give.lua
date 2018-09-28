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
	local num = base:get_friend_give_count(role)
	if num <= 0 then return  1205 end
	if frole then
		list = role.friends:check_give_one(data.id)
	else
		list = role.friends:check_give_all()
	end
	if not list or #list == 0 then return 1203 end
	local count = #list
	if count > num then
		table_sort(list, base:friend_comps() )
		count = num
	end
	local cost = {}
	cost[config.resource.diamond]  = config.give_diamond * (count)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.friends:set_give(list,count)
	role.base:add_give_count(count)
	local num = 0
	for k,friend in ipairs(list) do
		local id = friend:get_id()
		num = num +1
		local frole = roleMgr:get_role(id)
		if frole then frole.friends:give_to_receive(role:get_id()) end
		if num >= count then break end
	end
	return 0
end

return _M