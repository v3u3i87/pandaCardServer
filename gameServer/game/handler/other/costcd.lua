-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602

local _M = function(role,data)
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	local commander = nil
	if data.typ == 101 then
		commander = role.commanders:get(data.id)
		if not commander then return 400 end
	end

	local pass =  role.base:check_cost_cd(data.typ,data.pos)
	if not pass then return 3301 end
	local pass,cost = role.base:get_cost_cd(data.typ)
	if not pass then return 3300 end
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.base:add_cost_cd(data.typ)
	
	if data.typ == 101 then 	commander:skill_clear(data.pos) end

	return 0
end
return _M
