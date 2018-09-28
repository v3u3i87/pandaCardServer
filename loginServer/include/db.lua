local class = require "include.class"
local mysql = require "include.mysql"
local deepcopy = require "include.deepcopy"
local swapHashKV = require "include.swaphashkv"
local timetool = require "include.timetool"
local cjson = require "include.cjson"

local s_format = string.format
local s_find = string.find
local s_upper = string.upper
local s_sub = string.sub
local t_insert = table.insert
local t_concat = table.concat
local to_sqlstr = ngx.quote_sql_str

local _M = class()
_M.defaut_cache_time = timetool.one_hour

function _M:__init(ip,port,user,pw,db,tab,cols,colsdef,keys,upk,cache_time)
	if type(ip) == 'table' then 
		self.config = deepcopy(ip)
		ip = self.config.ip
	else 
		self.config = {} 
	end
	self.config.ip = self.config.ip or ip or "127.0.0.1"
	self.config.port = self.config.port or port or 3306
	self.config.user = self.config.user or user or "root"
	self.config.pw = self.config.pw or pw or "123456"
	self.config.db = self.config.db or db or "db"
	self.config.table = self.config.table or tab or "table"
	self.config.cols = self.config.cols or cols or {}
	self.config.colsdef = self.config.colsdef or colsdef or {}
	self.config.keys = self.config.keys or keys or {id='INT NOT NULL AUTO_INCREMENT'}
	self.config.upk = self.config.upk or upk or 'id'
	for i,v in pairs(self.config.keys) do
		t_insert(self.config.cols,1,i)
		t_insert(self.config.colsdef,1,v)
	end
	self.config.colsdefvalue = self.config.colsdefvalue or colsdefvalue or {}
	for i,v in ipairs(self.config.colsdef) do
		local key = self.config.cols[i]
		if not self.config.colsdefvalue[key] then
			local ups = s_upper(v)
			local sp,ep = s_find(ups,"DEFAULT",1,true)
			if sp and ep then
				self.config.colsdefvalue[key] = s_sub(v,ep+2)
			end
		end
	end

	self:check()
	self.select_all = s_format("SELECT * FROM `%s`",self.config.table)
	self.select_head = s_format("SELECT * FROM `%s` WHERE `%s` = ",self.config.table,self.config.upk)
	self.insert_head = {}
	t_insert(self.insert_head,s_format("INSERT INTO `%s` (`",self.config.table))
	t_insert(self.insert_head,t_concat(self.config.cols,"`,`"))
	t_insert(self.insert_head,"`) VALUES ")
	self.insert_head = t_concat(self.insert_head,"")
	self.insert_tail = {}
	for i,v in ipairs(self.config.cols) do
		t_insert(self.insert_tail,s_format("`%s`=VALUES(`%s`)",v,v))
	end
	self.insert_tail = s_format(" ON DUPLICATE KEY UPDATE %s",t_concat(self.insert_tail,","))
	--self.update_head = s_format("UPDATE `%s` SET ",self.config.table)
	self.delete_head = s_format("DELETE FROM `%s` WHERE `%s` IN (",self.config.table,self.config.upk)
	self.delete_all = s_format("DELETE FROM `%s`",self.config.table)
	self.delete_all_fast = s_format("TRUNCATE TABLE `%s`",self.config.table)
	
	self.update_rec = {}
	self.update_rec_num = 0
	self.bcache = true
	self.bcache_all = false
	self.rec = {}
	self.rec_up_time = {}
	self.max_upk_value = self:get_max_value(self.config.upk)
	self.cache_time = self.config.cache_time or cache_time or self.defaut_cache_time
	self.cache_num = 0
end

function _M:get_connect()
	return mysql:new(self.config.ip,self.config.port,self.config.user,self.config.pw,self.config.db)
end

function _M:excute(sql,con)
	local needclose = false
	if not con then 
		con = self:get_connect() 
		needclose = true
	end
	local rs,err = con:query(sql)
	if needclose then con:close() end
	if not rs then 
		ngx.log(ngx.ERR,"=====>excute sql error:", err, "sql: ", sql)
		return false,err
	end
	return rs
end

function _M:check()
	local con = self:get_connect()
	local create_sql = s_format("CREATE TABLE IF NOT EXISTS `%s` (`%s` %s, PRIMARY KEY (`%s`)) ENGINE=INNODB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC",self.config.table,self.config.upk,self.config.keys[self.config.upk],self.config.upk)
	local rs = self:excute(create_sql,con)
	if not rs then return false end
	local sql = s_format("SELECT COLUMN_NAME FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = '%s' AND `TABLE_NAME` = '%s'",self.config.db,self.config.table)
	local rs = self:excute(sql,con)
	if rs then
		local cs = {}
		for i,c in ipairs(rs) do
			cs[c.COLUMN_NAME] = 1
		end
		self.nc = {}
		local bchange = false
		for i,c in ipairs(self.config.cols) do
			if not cs[c] then
				self.nc[c] = self.config.colsdef[i] or "LONGTEXT"
				bchange = true
			end
		end
		
		local bchangekeys = false
		local defkeys = {}
		for c,def in pairs(self.config.keys) do
			if not cs[c] then
				bchangekeys = true
			end
			if c == self.config.upk then
				t_insert(defkeys,1,"`" .. c .. "`")
			else
				t_insert(defkeys,"`" .. c .. "`")
			end
		end
		if bchangekeys then
			defkeys = s_format("DROP PRIMARY KEY,ADD PRIMARY KEY (%s)",t_concat(defkeys,","))
		end
		
		if bchange then
			local adds = {}
			for c,t in pairs(self.nc) do
				t_insert(adds,s_format("ADD `%s` %s",c,t));
			end
			adds = t_concat(adds,",")
			local sql = ""
			if bchangekeys then
				sql = s_format("ALTER TABLE `%s` %s, %s",self.config.table,adds,defkeys)
			else
				sql = s_format("ALTER TABLE `%s` %s",self.config.table,adds)
			end
			if self:excute(sql,con) then self.nc = {} end
		end
	end
	con:close()
end

function _M:get_max_value(col,conditions,condition_values)
	local maxv = 0
	rs = false
	if not conditions or conditions == "*" then
		rs = self:excute(s_format("SELECT MAX(`%s`) FROM `%s`",col,self.config.table))
	else
		if type(conditions) ~= "table" then conditions = {[conditions]=condition_values} end
		local condition = {}
		for k,v in pairs(conditions) do
			t_insert(condition,s_format("`%s`=%s",k,to_sqlstr(v)))
		end
		rs = self:excute(s_format("SELECT MAX(`%s`) FROM `%s` WHERE %s",col,self.config.table,t_concat(condition," AND ")))
	end
	if rs and #rs > 0 then
		_,maxv = next(rs[1])
		if type(maxv) == "userdata" then maxv = 0 end
	end
	return maxv
end

function _M:get_record(npk_value,cols,npk)
	local rs = {}
	if not cols then 
		cols = "*"
	elseif type(cols) == "table" then
		cols = "`" .. t_concat(cols,"`,`") .. "`"
	else
		cols = "`" .. cols .. "`"
	end
	
	if not npk_value or npk_value == "*" then
		if self.bcache_all then
			rs = swapHashKV(deepcopy(self.rec),false)
		else
			rs = self:excute(s_format("SELECT %s FROM `%s`",cols,self.config.table))
			if rs and self.bcache and cols == "*" then
				self.cache_num = #rs
				self.rec = swapHashKV(deepcopy(rs),self.config.upk)
				self.bcache_all = true
			end
		end
	else
		if type(npk_value) ~= "table" then npk_value = {npk_value} end
		for i,v in ipairs(npk_value) do
			if self.rec[v] then
				t_insert(rs,deepcopy(self.rec[v]))
			else
				local r = self:excute(s_format("SELECT %s FROM `%s` WHERE `%s` = %s",cols,self.config.table,npk or self.config.upk,to_sqlstr(v)))
				if r and #r == 1 then	
					t_insert(rs,r[1])
					if bcache and cols == "*" then 
						self.rec[v] = deepcopy(r[1])
						self.cache_num = self.cache_num + 1
					end
				end
			end
		end
		if #rs == 1 then rs = rs[1] end
	end
	return rs
end

function _M:get_all_record(cols)
	return self:get_record(nil,cols)
end

function _M:cache(bcache,cache_time)
	self.bcache = bcache
	self.cache_time = cache_time or self.cache_time
	if not bcache then
		self.rec = {}
		self.rec_up_time = {}
		self.cache_num = 0
		self.bcache_all = false
	end
end

function _M:get_cache_num()
	return self.cache_num
end

function _M:get_update_rec_num()
	return self.update_rec_num
end

function _M:get_next_upk_value()
	self.max_upk_value = self.max_upk_value + 1
	return self.max_upk_value
end

function _M:check_rec(rec,bappend)
	if not rec[self.config.upk] then return false end
	local oldrec = self.rec[rec[self.config.upk]] or (self.update_rec[rec[self.config.upk]] and self.update_rec[rec[self.config.upk]].rec)
	if not oldrec and not bappend then
		oldrec = self:get_record(rec[self.config.upk])
	end
	for i,v in ipairs(self.config.cols) do
		if not rec[v] and oldrec then rec[v] = oldrec[v] end
		if rec[v] and type(rec[v]) ~= "string" and type(rec[v]) ~= "number" then rec[v] = cjson.encode(rec[v]) end
	end
	if bcache then
		self.rec[rec[self.config.upk]] = rec 
		self.rec_up_time[rec[self.config.upk]] = timetool:now()
	end
	return true
end

function _M:append(rec)
	rec[self.config.upk] = self:get_next_upk_value()
	return self:update(rec,true)
end

function _M:remove(upk_value,fast)
	local rs = false
	if not upk_value or upk_value == "*" then
		if fast then rs = self:excute(self.delete_all_fast)
		else rs = self:excute(self.delete_all) end
		self.rec[v] = {}
	else
		if type(upk_value) ~= "table" then upk_value = {upk_value} end
		for i,v in ipairs(upk_value) do
			self.rec[v] = nil
			upk_value[i] = to_sqlstr(v)
		end
		rs = self:excute(s_format("%s %s)",self.delete_head,t_concat(upk_value)))
	end
	return rs
end

function _M:update(rec,bappend)
	rec = deepcopy(rec)
	if not self:check_rec(rec,bappend) then return false end
	local t = {}
	for i,v in ipairs(self.config.cols) do
		t[i] = rec[v] or self.config.colsdefvalue[v] or "NULL"
		if t[i] ~= "NULL" then
			t[i] = to_sqlstr(t[i])
		end
	end
	if not self.update_rec[rec[self.config.upk]] then self.update_rec_num = self.update_rec_num + 1 end
	self.update_rec[rec[self.config.upk]] = {rec=rec,sql=s_format("(%s)",t_concat(t,","))}
	
	return true
end

function _M:save(limit)
	local n = 0
	local insert = {}
	local insert_ids = {}
	for i,v in pairs(self.update_rec) do
		t_insert(insert,v.sql)
		t_insert(insert_ids,i)
		n = n + 1
		if limit and n >= limit then break end
	end
	if n == 0 then return true,n end

	local rs,err = self:excute(s_format("%s%s%s",self.insert_head,t_concat(insert,","),self.insert_tail))
	if not rs then return false,err end
	for i,v in ipairs(insert_ids) do
		self.update_rec[v] = nil
	end
	self.update_rec_num = self.update_rec_num - n
	return true,n
end

function _M:clean(force)
	if force then 
		self:save()
		self.rec = {}
		self.rec_up_time = {}
		self.cache_num = 0
	else
		if not bcache then return true end
		local ct = timetool:now() - self.cache_time
		for i,v in pairs(self.rec) do
			local upt = self.rec_up_time[i] or 0
			if upt < ct then 
				self.rec[i] = nil
				self.rec_up_time[i] = nil
				self.cache_num = self.cache_num - 1
			end
		end
	end
	
	return true
end

return _M