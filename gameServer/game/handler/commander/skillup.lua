-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.commander"
local task_config = require "game.template.task"

local _M = function(role,data)
	if not data.skillid or type(data.skillid) ~= "number" then return 2 end
	data.count = tonumber(data.count or 1)
	if data.count > 10 then data.count = 10 end
	
	local id = data.id or 101
	local commander = role.commanders:get(id)
	if not commander then return 400 end
		
	for i=1,data.count do
		local canup = config:canup_skill(commander,data.skillid)
		if not canup then return 101 end
		
		local cost = config:get_skill_up_cost(commander,data.skillid)
		if not cost then return 4 end
		local enough,diamond,cost = role:check_resource_num(cost)
		if not enough then
			if data.usediamond ~= 1 or role.base:get_diamond() < diamond then
				if i > 1 then
					return 0,{data= i-1}
				else
					return 100
				end
			end
		end

		role:consume_resource(cost)
		commander:skill_up(data.skillid,cost)
	end
	if data.skillid == 101 then	role.tasklist:trigger(task_config.trigger_type.skill_base_level)	end
	return 0,{data = data.count}
end

return _M
