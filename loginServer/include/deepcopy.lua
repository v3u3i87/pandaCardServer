function deepcopy(data)
	local copy = data
	if type(data) == 'table' then
		copy = {}
		for i,v in pairs(data) do
			copy[i] = deepcopy(v)
		end
	end
	return copy
end

local _M = deepcopy

return _M