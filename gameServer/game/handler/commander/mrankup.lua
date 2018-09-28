-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.commander"

local _M = function(role,data)
	local id = data.id or 101
	local commander = role.commanders:get(id)
	if not commander then return 400 end
	
	local canup = config:canup_mrank(commander)
	if not canup then return 101 end
	
	local cost = config:get_mrank_up_cost(commander)
	if not cost then return 4 end
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then
		if data.usediamond ~= 1 or role.base:get_diamond() < diamond then return 100 end
	end
	
	local bsuc,bless = config:calc_mrankup_suc(commander)
	role:consume_resource(cost)
	commander:mrank_up(bsuc,bless,cost)
	local suc = 0
	if bsuc then suc = 1 end
	return 0,{data={suc=suc,bless=bless}}
end

return _M
