
local _M = function(url,args,method)
	local loc = '/proxy/' .. url
	local res = ngx.location.capture(loc,
		{
			method = method or ngx.HTTP_GET,
			args = args
		}
	)
	if 200 ~= res.status then
		return false,"http errror code " .. res.status
	end
	
	return true,res.body
end

return _M