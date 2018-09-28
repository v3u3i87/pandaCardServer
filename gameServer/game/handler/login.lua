-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local accMgr = require "manager.accMgr"
local roleMgr = require "manager.roleMgr"
local global = require "game.global"
local config = require "game.config"
local geturl = require "include.geturl"
local md5 = ngx.md5
local task_config = require "game.template.task"
local cjson = require "cjson"


local _M = function(role,data)
	if not data.uid or not data.verify or type(data.verify) ~= "string" then return 2 end
	if data.uid == "gm" then
		if data.verify ~= md5(global.gm_password) then return 201 end
		return 0
	end
	if not accMgr:is_login(data.uid) then return 200 end
	if not accMgr:check_verify(data.uid,data.verify) then return 201 end
	
	local role,bcreate = roleMgr:load_role(data.uid)
	if not role then return 202 end
	
	if	config.acc_address then 
		local cid = role:get_cid()
		--ngx.log(ngx.ERR,"cid:",cid)
		local ok,res = geturl(config.acc_address,{
		type = "acc",
			cid = cid,
			id = config.server_id
		},ngx.HTTP_GET)
		--ngx.log(ngx.ERR,"res:",res)
		local ok,getdata = pcall(cjson.decode,res)
		if ok and type(getdata) == 'table' then
			--ngx.log(ngx.ERR,"getdata.status:",getdata.status)
			if	getdata.status	 >0 then return res end
		else
			ngx.log(ngx.ERR,"res:",res)
			return 203
		end
	end
	
	local bc = 0
	local rdata = nil
	local name = ""
	if bcreate then 
		bc = 1
		role:update()
		role.extend:calc_offline()
		rdata = role:get_client_data()
	else
		role.soldiers:conscripts(1011,1)
		role.army:go_battle(1011,1)

		--name = role.random_name()
	end
	if role.tasklist then role.tasklist:trigger(task_config.trigger_type.login,1) end
	if role.both then role.both:check_refresh_list() end

	return 0,{
		id = role.id,
		bcreate = bc,
		data = rdata,
		name = name,
	}
end

return _M
