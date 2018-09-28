-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or not data.itemtype then return 2 end
	data.pos = tonumber(data.pos)
	data.itemtype = tonumber(data.itemtype)
	if data.itemtype < 1 or data.itemtype > 6 then return 2 end
	if data.pos < 1 or data.pos > 10 then return 700 end
	
	local ok = role.army:take_off_equipment(data.pos,data.itemtype)
	if not ok then return 704 end
	return 0
end

return _M
