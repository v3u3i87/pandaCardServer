-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "login.config"
local mysql = require "include.mysql"
local cidMgr = require "manager.cidMgr"
local cjson = require "include.cjson"


local md5 = ngx.md5

local function check_string(str)
	if not str then str = "" end
	return ngx.quote_sql_str(tostring(str))
end

local _M = function(args)
	if not args then return false,"no params" end
	if not args.acc or not args.pw then return false,"no params" end
	if type(args.acc) ~= 'string' or type(args.pw) ~= 'string' then return false,"params format error" end
	
	local acc = check_string(args.acc)
	local pw = tostring(args.pw)
	local info = nil
	local cid = false
	
	local con = mysql:new(config.account_db.ip,config.account_db.port,config.account_db.user,config.account_db.pw,config.account_db.db)
	local sql = "SELECT * FROM " .. config.account_db.table .. " WHERE acc=" .. acc
	local result,errmsg = con:query(sql)
	if not result then
		return false,"query from account table failed==>" .. errmsg
	end

	if #result > 0 then
		if md5(pw) ~= result[1].pw then return false,"password error" end
		cid = result[1].id
		--modify info
		--if not info then
		--	sql = "SELECT * FROM " .. config.account_db.table .. " WHERE acc=" .. acc
		--end
		info = result[1].info
	else
		info = args.info
		sql = "INSERT INTO " .. config.account_db.table .. "(acc,pw,info) VALUES (" .. acc .. "," .. check_string(md5(pw)) .. "," .. check_string(info) .. ")"
		local result,errmsg = con:query(sql)
		if not result then
			return false,"query from account table failed==>" .. errmsg
		end
		cid = result.insert_id
	end
	con:close()
	local key = cidMgr:login_key(cid)
	--cid,cn,acc,pw,time
	--calc token
	
	--record acc,pw,token
	
	--make result
	
	--return {
	--	token = md5(cid..os.time()),
	--	info = info,
	--}
	--return true,cid,info
	local res ={status = 0,key=key} 
	return ngx.say(cjson.encode(res))
end

return _M