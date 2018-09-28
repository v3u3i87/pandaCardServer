-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local cjson = require "include.cjson"

local process_error = function(code,msg)
	local m = {
		status = code,
		msg = msg
	}
	ngx.say(cjson.encode(m))
end

local args = ngx.req.get_uri_args()
if type(args.type) ~= "string" then return process_error(1,"wrong params") end

local ok,login = pcall(require,"login."..args.type)
if not ok or type(login) ~= 'function' then return process_error(2,"wrong params") end

local ok,cid,info = login(args)
local res = cid
res.status = 0
return ngx.say(cjson.encode(res))