-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.num or type(data.num) ~= "number" then return 2 end



	local pass,typ =  role.shop:can_buy(data.id,data.num,data.pos)
	if not pass then return 2700 end
	local cost = role.shop:get_buy_cost(data.id,data.num,typ)
	local en,diamond,cost = role:check_resource_num(cost)
	if not en then return 100 end
	role:consume_resource(cost)
	local profit = role.shop:buy(data.id,data.num,typ,data.pos)
	role:gain_resource(profit)
	return 0,{data = profit}
end
return _M
