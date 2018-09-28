local s_find = string.find
local s_sub = string.sub
local t_insert = table.insert
--将hash表的key值转换为number类型输出
local _M = function(str,p,ismatch)
	local r = {}
	local last = str
	local s,e = s_find(last,p,1,not ismatch)
	while s do
		local s1 = s_sub(last,1,s-1)
		if #s1 > 0 then
			t_insert(r,s1)
		end
		last = s_sub(last,e+1)
		s,e = s_find(last,p,1,not ismatch)
	end
	t_insert(r,last)
	return r
end

return _M