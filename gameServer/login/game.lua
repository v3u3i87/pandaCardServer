-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local accMgr = require "manager.accMgr"
local config = require "login.config"
local mysql = require "include.mysql"
local CDb = require "include.db"


local function check_string(str)
	if not str then str = "" end
	return ngx.quote_sql_str(tostring(str))
end

local _M = function(args)
	local db = CDb:new(config.user_db)

	if not args or not args.cid then return false,"wrong parameter3" end
	local uid = nil
	local cid = check_string(args.cid)
	local cn = check_string(args.cn)
	local info = check_string(args.info)
	
	local con = mysql:new(config.user_db.ip,config.user_db.port,config.user_db.user,config.user_db.pw,config.user_db.db)	
	local sql = "SELECT * FROM " .. config.user_db.table .. " WHERE cid=" .. cid
	local result,errmsg = con:query(sql)
	if not result or #result > 1 then
		return false,"query failed from account table==>" .. errmsg
	end

	if #result == 0 then
		sql = "INSERT INTO " .. config.user_db.table .. "(cid,cn,info) VALUES (" .. cid .. "," .. cn .. "," .. info .. ")"
		local result,errmsg = con:query(sql)
		if not result then
			return false,"query failed from account table==>" .. errmsg
		end
		uid = result.insert_id
	else
		uid = result[1].uid
		cn = result[1].cn
		info = result[1].info
	end
	
	--ngx.log(ngx.ERR,"cid:",cid," uid:",uid)

	con:close()
	accMgr:login(uid,cid,cn,info)
	local ret = {
		uid = uid,
		verifycode = accMgr:get_verifycode(uid)
	}
	return true,ret
end

return _M