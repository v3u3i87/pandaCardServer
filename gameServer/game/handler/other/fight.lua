-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602

local _M = function(role,data)
	if not data.num or type(data.num) ~= "number" then return 2 end
	role.base:set_fight_point(data.num)
	return 0
end
return _M
