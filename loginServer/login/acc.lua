-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CDb = require "include.db"
local t_insert = table.insert
local config = require "login.config"
local cjson = require "include.cjson"
local s_len = string.len

local function add_id(cid,id)
	id = tonumber(id)
	cid = tonumber(cid)
	local db = CDb:new(config.record_db)
	local data = db:get_record(cid,nil,"cid")
	local b_install =false
	if not data or not data.list then 
		data ={
			cid = cid,
			cn = "",
			info = "",
			list = "[]"
		}
		b_install = true 
	end

	local list = {}
	if s_len(data.list) >2 then list = cjson.decode(data.list) or {} end

	local hlistbuf = {}
	for i=1,#list do
		if list[i] ~= id then t_insert(hlistbuf,list[i]) end
	end
	t_insert(hlistbuf,1,id)
	data.list = hlistbuf
	if b_install then db:append(data)
	else db:update(data) end
	db:save()
end


local _M = function(args)
	if not args then return false,"no params1" end
	if not args.cid or not args.id then return false,"no params2222" end
	add_id(args.cid,args.id)
	local res ={status = 0} 
	return ngx.say(cjson.encode(res))
end

return _M