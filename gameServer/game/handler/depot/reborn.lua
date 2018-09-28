-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local t_insert = table.insert
local mergeProfit = require "game.model.merge_profit"

local _M = function(role,data)
	if not data.ids then return 2 end


	local t = type(data.ids)
	if t == "number" then data.ids = {data.ids}
	elseif t ~= "table" then return 2 end
	
	local p = {}
	for i,v in ipairs(data.ids) do
		local np = role.depot:reborn(v)
		if np then t_insert(p,np) end
	end
	
	return 0,{data=mergeProfit(unpack(p))}
end

return _M
