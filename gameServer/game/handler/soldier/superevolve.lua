-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.soldier"
local open_config = require "game.template.open"

--超进化　－〉　改造
local _M = function(role,data)
	if not data.id then return 2 end
	if not open_config:check_level(role,open_config.need_level.soldier_superevolve) then return 101 end

	local soldier = role.soldiers:get(data.id)
	if not soldier then return 500 end

	local canup = config:cansuperevolve(soldier)
	if not canup then return 101 end
	
	local cost = config:get_superevolve_cost(soldier)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then return 100 end
	role:consume_resource(cost)
	soldier:sq_up(cost)
	return 0
end

return _M
