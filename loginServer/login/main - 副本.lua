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
if args.type == "acc"  then return ngx.say(cjson.encode({ok = ok,status = cid}))  
elseif args.type == "get_svrlist"  then return ngx.say(cjson.encode({s_serverIp = cid}) )
elseif args.type == "get_notify"  then return ngx.say(cjson.encode({content = cid}) )
elseif args.type == "get_svr_history"  then return ngx.say(cjson.encode({history = cid}) )
end

if not ok then return process_error(1,cid) end

local login_game = require "login.game"

local ok,result = login_game(cid,args.type,info)
if not ok then return process_error(1,result) end

result.status = 0

return ngx.say(cjson.encode(result))