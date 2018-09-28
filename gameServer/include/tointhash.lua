
--将hash表的key值转换为number类型输出
local _M = function(hash)
	local intHash = {}
	for k,v in pairs(hash) do
		intHash[tonumber(k)] = v
	end
	return intHash
end

return _M