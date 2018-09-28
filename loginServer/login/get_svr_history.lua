-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "login.config"

local mysql = require "include.mysql"
local CDb = require "include.db"
local cjson = require "include.cjson"

local function get_history(cid,cn)
	if not cid then return false,"wrong parameter" end
	local historylist ={}
	local db = CDb:new(config.record_db)

	local con = mysql:new(config.record_db.ip,config.record_db.port,config.record_db.user,config.record_db.pw,config.record_db.db)	
	local sql = "SELECT * FROM " .. config.record_db.table .. " WHERE cid=" .. cid
	local result,errmsg = con:query(sql)
	ngx.log(ngx.ERR,"sql:",sql)
	ngx.log(ngx.ERR,"result:",cjson.encode(result))
	if result and #result > 0 then
		historylist = cjson.decode(result[1].list) or {}
	end
	con:close()
	return historylist
end

local _M = function(args)
	if not args or not args.cid or not args.cn then return false,"no params1" end
	local historylist = get_history(args.cid,args.cn)
	return ngx.say(cjson.encode({history = historylist}) )
end

return _M