-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local fund_config = require "game.template.fund"
local _M = function(role,data)
	if not data.id then data.id = 2 end
	data.id = tonumber(data.id)
	local pass = role.base:can_fund_reward(data.id)
	if not pass then return 3006 end
	local profit = fund_config:get_fund_reward_profit(data.id)
	role:gain_resource(profit)
	role.base:add_fund_reward(data.id)
	return 0,{data = profit}
end
return _M
