-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local slen = string.len
local _M = function(role,data)
	if not data.id or type(data.id) ~= "number" then return 2 end
	local frole = nil
	if data.pn and type(data.pn) == "string" and slen(data.pn) >0 then
		frole = roleMgr:get_role_byname(data.pn)
		if not frole then return 1903 end
	end
	if not data.pn then data.pn = role:get_name() end
	if not role.boss:is_begin(data.id,data.pn) then return 1902 end

	local pass =nil
	local cost_num =0 
	if frole then
		if frole.boss:is_boss_die() then return 1903 end
		pass,cost_num = role.boss:can_other_challenge(data.id,data.typ)
		if not pass then return 1902 end
	else
		pass,cost_num = role.boss:can_challenge(data.id,data.typ)
		if not pass then return 1902 end
	end
	role.boss:cost_challenge(cost_num)
	role.boss:set_challage_begin_time(data.id,data.pn)
	return 0
end
return _M
