-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.pos or not data.itemid then return 2 end
	if type(data.itemid) ~= "table" then return 2 end
	data.pos = tonumber(data.pos)
	if data.pos < 1 or data.pos > 10 then return 700 end
	
	for i,v in ipairs(data.itemid) do
		if not role.army:is_equipment(data.pos,i+2,v ) and v > 0  then --装备3~6
			local item = role.depot:get(v)
			if not item then return 600 end
			local ok = role.army:wear_equipment(data.pos,item)
			if not ok then return 601 end
		end
	end
	return 0
end

return _M
