-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or not data.itemid then return 2 end
	data.pos = tonumber(data.pos)
	data.itemid = tonumber(data.itemid)
	if data.pos < 1 or data.pos > 10 then return 700 end
	
	local item = role.depot:get(data.itemid)
	if not item then return 600 end
	local ok = role.army:wear_equipment(data.pos,item)
	if not ok then return 601 end
	return 0
end

return _M
