-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local tasklist = require "game.template.task"

local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.num or type(data.num) ~= "number" then return 2 end
	if not data.win or type(data.win) ~= "number" then return 2 end
	if data.id <= 0 or data.id >9 then return 1700 end
	local item_config = require "game.template.item"
	if not role.depot:check_depot_full(item_config.type.equipment) then return 602 end

	local pass = role.arsenal:can_challenge(data.id,data.num,role:get_level())
	if not pass then return 1704 end
	if data.win ~= 1 then return 1701 end
	local profit,profit_send = role.arsenal:get_challenge_profit(data.id,data.num)
	role:gain_resource(profit)
	role.arsenal:cost_challenge(data.id,data.num)
	return 0,{data=profit_send}
end
return _M
