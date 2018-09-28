-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.em or type(data.em) ~= "table" then return 2 end
	local em = {}
	for i=1,8 do
		if not data.em[i] then return 2 end
		em[i] = data.em[i]
	end
	
	role.army:set_embattle(em)
	return 0
end

return _M
