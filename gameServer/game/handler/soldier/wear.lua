-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.soldier"

local _M = function(role,data)
	if not data.id then return 2 end
	if not data.pos then return 2 end
	if data.pos <=0 or data.pos >5 then return 2 end
	local soldier = role.soldiers:get(data.id)
	if not soldier then return 500 end

	local canup = config:canwear(soldier,data.pos)
	if not canup then return 101 end
	
	local cost,eqid = config:get_wear_cost(soldier,data.pos)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then	 return 100 end
	role:consume_resource(cost)
	soldier:wear(data.pos,eqid)
	return 0
end

return _M
