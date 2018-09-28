-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.template.boss"
local _M = function(role,data)
	if not data.num then data.num = 1 end
	local get_num = role.knapsack:get_num(config.boss_challage_id)
	if num < get_num then return 100 end
	local cost = {[config.boss_challage_id] = data.num}
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	role.boss:add_challenge_count(data.num)
	return 0
end
return _M
