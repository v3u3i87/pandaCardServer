-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id or not data.pos or type(data.pos) ~= "number" then return 2 end
	if data.pos < 1 or data.pos > 10 then return 700 end
	
	local soldier = role.soldiers:get(data.id)
	if not soldier then return 500 end
	if not role.army:can_fill("companion",data.pos) then return 701 end
	role.army:go_companion(data.id,data.pos)
	
	return 0
end

return _M
