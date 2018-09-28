-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.soldier"

local _M = function(role,data)
	if not data.id then return 2 end
	data.count = tonumber(data.count or 1)
	local soldier = role.soldiers:get(data.id)
	if not soldier then return 500 end

	for i=1,data.count do
		if soldier:get_level() +1 > role:get_level() then return 501 end

		local canup = config:canup(soldier)
		if not canup then return 101 end
		
		local cost = config:get_level_up_cost(soldier)
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
		soldier:level_up(cost)
	end

	return 0,{data = data.count}
end

return _M
