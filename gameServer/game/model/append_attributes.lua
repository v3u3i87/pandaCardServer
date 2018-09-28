-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local attributeid = config.template.attributeid

local _M = function(atrrs,conf,mx)
	mx = mx or 1
	if conf and #conf > 0 then
		if type(conf[1]) ~= "table" then conf = {conf} end
		for i,v in ipairs(conf) do
			atrrs[v[1]] = atrrs[v[1]] or 0
			if v[2] == 1 or v[1] > 12 then
				atrrs[v[1]] = atrrs[v[1]] + v[3] * mx
			elseif v[2] == 2 then
				atrrs[v[1]] = atrrs[v[1]] + atrrs[v[1]] * v[3]/10000 * mx
			end
		end
	else
		for i,v in pairs(attrs) do
			if v[1] < 13 then
				atrrs[v[1]] = atrrs[v[1]] * mx
			end
		end
	end
end

return _M