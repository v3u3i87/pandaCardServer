-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local cjson = require "include.cjson"
local config = require "login.server"
local geturl = require "include.geturl"
local cidMgr = require "manager.cidMgr"

local process_error = function(code,msg)
	local m = {
		status = code,
		msg = msg
	}
	ngx.say(cjson.encode(m))
end

local args = ngx.req.get_uri_args()
if type(args.type) ~= "string" then return process_error(1,"wrong params") end

if args.type == "choose" then
	if not args.cid or not args.key  then return process_error(3,"wrong params") end
	--check token
	--get acc,pw
	--if not cidMgr:check_verify(args.cid,args.key) then return process_error(4,"check_verify.false") end
	
	local host = config:get_host(args.id)
	ngx.log(ngx.ERR,"host:",host, " args.id:",args.id)
	--通过服务器id，得到uid,verifycode
	local ok,res = geturl(host,{
		type = "game",
		cid = args.cid,
		cn = args.cn,
		info = info
	},ngx.HTTP_GET)
	ngx.log(ngx.ERR,"res:",res)
	return ngx.say(res)
else
	local ok,login = pcall(require,"login."..args.type)
	if not ok or type(login) ~= 'function' then 
		ngx.log(ngx.ERR,"login:",login)
		return process_error(2,"wrong params") 
	end
	
	local ok,cid,info = login(args)
	if not ok then return process_error(1,cid) end
	
	--[[if args.type == "get_svrlist"  then return ngx.say(cjson.encode({s_serverIp = cid}) )
	elseif args.type == "get_notify"  then return ngx.say(cjson.encode({content = cid}) )
	elseif args.type == "get_svr_history"  then return ngx.say(cjson.encode({history = cid}) )
	end
	local res = cid
	if type(res) ~= "table" then res ={status = 0,cid=cid} 
	else res.status = 0 
	end
	
	return ngx.say(cjson.encode(res))]]--
end
