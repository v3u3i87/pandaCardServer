local t_insert = table.insert
local s_gsub = ngx.re.gsub
local s_find = string.find
local s_upper = string.upper
--获取指定目录下的所有扩展名为ext的文件
local is_win = nil
function sys_is_window()
	if is_win ~= nil then return is_win end
	local ostype = s_upper(os.getenv("OS") or "")
	return s_find(ostype,"WIN",1,true)
end

function _M(dir,ext,files)
	files = files or {}
	local file = nil
	local sp = "/"
	if sys_is_window() then
		file = io.popen("dir /b " ..s_gsub(dir,sp,"\\"), "rb")
	else
		file = io.popen("ls " .. dir)
	end
	if not file then return files end
	local p = s_gsub(dir, sp, ".")
	for line in file:lines() do
		_,_, fn,e = s_find(line, "([^\n\r%.]+)[%.]?([^\n\r]*)")
		if fn then
			if e == "" then
				_M(dir .. sp .. fn,ext,files)
			elseif not ext or e == ext then
				t_insert(files,p .. "." .. fn)
			end
		end
	end
	return files
end

return _M