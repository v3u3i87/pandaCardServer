local t_insert = table.insert
--将hash表的key,value交换
--key == nil ===>直接交换key-value
--key == false ===>去掉key,将hash表转换为array
--key ~= nil ===>将value[key]作为新的key
local _M = function(hash,key)
	local newHash = {}
	if not key then
		if key == false then
			for k,v in pairs(hash) do
				t_insert(newHash,v)
			end
		else
			for k,v in pairs(hash) do
				newHash[v] = k
			end
		end
	else
		for k,v in pairs(hash) do
			if type(v) == "table" and v[key] then
				newHash[v[key]] = v
			end
		end
	end
	return newHash
end

return _M