-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(...)
	local p = {}
	local args = {...}
	for i,v in ipairs(args) do
		for k,n in pairs(v) do
			p[k] = (p[k] or 0) + n
		end
	end
	return p
end

return _M