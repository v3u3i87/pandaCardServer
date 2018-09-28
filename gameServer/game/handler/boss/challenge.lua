-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"

local slen = string.len
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	if not data.typ or type(data.typ) ~= "number" then return 2 end
	if not data.damage or type(data.damage) ~= "number" then return 2 end
	if data.typ ~= 1 and data.typ ~= 2 then return 1901 end
	local frole = nil
	if data.pn and type(data.pn) == "string" and slen(data.pn) >0 then
		frole = roleMgr:get_role_byname(data.pn)
		if not frole then return 1903 end
		if frole.boss:is_boss_die() then return 1903 end
	elseif role.boss:is_boss_die() then return 1903 end

	if not data.pn then data.pn = role:get_name() end
	if not role.boss:check_begin_time(data.id,data.pn) then return 1902 end
	local pass =nil
	local cost_num =0 
	if frole then
		role.boss:other_challenge(data.damage)
		frole.boss:add_damage(data.damage,data.id)
	else
		role.boss:challenge(data.damage,data.id)
	end
	local profit = role.boss:get_challenge_profit(data.id)
	role:gain_resource(profit)
	role.boss:challenge_end(data.id,data.pn)
	return 0,{data=profit}
end
return _M
