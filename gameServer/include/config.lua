local file = require "include.file"
local cjson = require "include.cjson"
local getfiles = require "include.getdirfiles"

local s_upper = string.upper
local s_find = string.find

local _M = {}

_M.net = {
	timeout = 6000,
	--max_len = 65535,
	max_payload_len = 200000
}

_M.db = {
	base = {
		ip = "127.0.0.1",
		port = 3306,
		user = "root",
		pw = "123456",
		db = "ace_account",
	},
	tables = {
		role = {
			table = "role",
			cols = {"uid","rname","extend"},
			colsdef = {"INT NOT NULL","CHAR(64) DEFAULT ''","LONGTEXT DEFAULT NULL"},---字段类型默认为LONGTEXT，可以不定义
			--keys = {id='INT NOT NULL AUTO_INCREMENT'},--默认key为id
			--upk = "id",
		},
		mail = {
			table = "mail",
			cols = {"createtime","failuretime","sender","need_receivers","receivers","content"},
			colsdef = {"INT NOT NULL","INT NOT NULL","INT NOT NULL","LONGTEXT DEFAULT NULL","LONGTEXT DEFAULT NULL","LONGTEXT DEFAULT NULL"},
		},
		rank = {
		},
		log = {
			table = "log",
			cols = {"request_time","return_time","task","content","status","result","role_id","client_ip"},
			colsdef = {"INT","INT","LONGTEXT","LONGTEXT","INT","LONGTEXT","INT","LONGTEXT"},
		}
	},
}

_M.role = {
	attributes = {"extend"},
	dead_time = 7*24*3600,
	save_interval = 60,
	clean_interval = 3600,
	update_interval = 10,
	model = "include.role"
}

_M.rank = {
--[[
	level = {
		id = 1,
		asc = false
	}
--]]
}

_M.mail = {
	save_interval = 60,
	failure_time = 30*24*3600,
	model = "include.mail",
}

_M.log = {
	active = true,
	save_interval = 60,
}

_M.update_obj = {
	--cmb_reset = {data="commanders",fun="reset_mrank_bless",ut={d=-1,h=5,m=0,s=0},once=true},
}

_M.template = {}

_M.conf_names = {}

function _M:init_config(name,idxn1,idxn2)
	local json,err = file:load("game/config/" .. name .. ".json")
	if not json then
		ngx.log(ngx.ERR,"init config error : game.config." .. name .. '===>' .. err )
		return 
	end
	--ngx.log(ngx.ERR," name:",name)
	local conf = cjson.decode(json)
	if not idxn1 then
		_M.template[name] = conf
	else
		_M.template[name] = {}
		for i,v in ipairs(conf) do
			if v[idxn1] then
				if idxn2 then
					if v[idxn2] then
						_M.template[name][v[idxn1]] = _M.template[name][v[idxn1]] or {}
						_M.template[name][v[idxn1]][v[idxn2]] = v
					end
				else
					_M.template[name][v[idxn1]] = v
				end
			end
		end
	end
end

function _M:init()
	ngx.log(ngx.ERR,"old config init1")
	for i,v in pairs(self.conf_names) do
		self:init_config(i,v[1],v[2])
	end
ngx.log(ngx.ERR,"old config init2")
	local files = getfiles("game/template","lua")
	for i,v in ipairs(files) do
		local temp = require(v)
		if temp and temp.__init then
			temp:__init()
		end
	end
	ngx.log(ngx.ERR,"old config init3")
end

function _M:get_db_config(model)
	local dbconfig = self.db.tables[model]
	if not dbconfig then return false end
	dbconfig.ip = dbconfig.ip or self.db.base.ip
	dbconfig.port = dbconfig.port or self.db.base.port
	dbconfig.user = dbconfig.user or self.db.base.user
	dbconfig.pw = dbconfig.pw or self.db.base.pw
	dbconfig.db = dbconfig.db or self.db.base.db
	return dbconfig
end

return _M