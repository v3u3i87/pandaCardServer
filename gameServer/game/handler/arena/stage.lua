-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or type(data.pos) ~= "number" then return 2 end
	if not data.num or type(data.num) ~= "number" then return 2 end
	if not data.win or type(data.win) ~= "number" then return 2 end
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	local pass =  role.arena:can_stage(data.pos,data.num,data.typ)
	if not pass then return 2104 end
	local profit = role.arena:stage(data.pos,data.num,data.win,data.typ)
	role:gain_resource(profit)
	--local anana_ranks = {}
	--if data.typ ~= 1 and data.win == 1 then  anana_ranks =  role.arena:refresh() end
	return 0,{data=profit,typ = data.typ}
end
return _M
