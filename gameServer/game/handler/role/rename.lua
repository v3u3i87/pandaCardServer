-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local base = require "game.template.base"

local _M = function(role,data)
	if not data.name or type(data.name) ~= "string" then return 2 end
	local length = #data.name 
	if length < 2 or length > 64 then return 301 end
	--check data.name 
	local cn = ngx.quote_sql_str(data.name)
	if #cn - length ~= 2 then return 301 end
	
	if roleMgr:is_name_exist(data.name) then return 300 end
	local cost = base:check_rename(role.base:get_change_name_num())
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)

	local oldname = role:get_name()
	roleMgr:role_rename(role.id,oldname,data.name)
	role:set_name(data.name)
	role.base:add_change_name_num()
	role.commanders:choose_commander(data.id)
	local rd = nil
	if not oldname or oldname == "" then rd = role:get_client_data() end
	return 0,{data=rd}
end

return _M
