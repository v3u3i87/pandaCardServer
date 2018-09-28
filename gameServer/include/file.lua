local _M = {}

function _M:load(filename)
	if filename == nil then return nil end
	local file, err = io.open(filename, "rb")
	if file == nil then return nil,err; end
	local data = file:read("*a")
	file:close()
	return data;	
end

function _M:save()
	if filename == nil then return false end
	local file, err = io.open(filename, "wb")
	if file == nil then return false,err; end
	file:write(data)
	file:close()
	return true
end

function _M:append(filename, data)
	local file, err = io.open(filename, "ab")
	if file == nil then return false,err end
	file:write(data)
	file:close()
	return true
end

return _M;