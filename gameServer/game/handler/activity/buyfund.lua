-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local fund_config = require "game.template.fund"
local _M = function(role,data)
	local pass = role.base:can_buy_fund()
	if not pass then return 3005 end
	local cost = fund_config:get_buy_fund_cost()
	local enough,diamond,cost = role:check_resource_num(cost)
	if not enough then return 100 end
	role:consume_resource(cost)
	role.base:set_fund()
	return 0
end
return _M
