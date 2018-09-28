-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local config = require "game.config"
local math_random = math.random
local table_insert = table.insert
local math_floor =  math.floor
local cjson = require "include.cjson"

local _M = {}
_M.data = {
	shopCar = config.template.shopCar,
	shopHero = config.template.shopHero,
	shopEqu = config.template.shopEqu,
	shopCommon = config.template.shopCommon,
	armyrelation = config.template.armyrelation,
	shop_armyfrag= config.template.shop_armyfrag,
	shopAre = config.template.shopAre,
}
_M.interval_time	= 3600*2		--2小时会自动恢复1次
_M.shop_soldier_refresh_free = 4
_M.shop_soldier_refresh_max = 20
_M.shop_soldier_refresh_id1 = 10
_M.shop_soldier_refresh_id1_num = 1
_M.shop_soldier_refresh_id2 = 17
_M.shop_soldier_refresh_id2_num = 20
_M.shop_soldier_shop_num = 6
_M.shop_soldier_get_good_refresh_num  = 3
_M.shop_type ={
	common 	= 1,
	hero 	= 2,
	equ 	= 3,
	car 	= 9,
	arena     = 5,
}
_M.require_type ={
	vip = 1,
	stage = 2,
}

function _M:get_type(index)
	return math_floor(index / 1000)
end

function _M:get_shop(index)
	local data ={}
	local typ = self:get_type(index)
	if typ == self.shop_type.common then
		if not self.data.shopCommon[index] then return false
		else data = self.data.shopCommon[index] end
	elseif typ == self.shop_type.hero then
		if not self.data.shopHero[index] then return false
		else data = self.data.shopHero[index] end
	elseif typ == self.shop_type.equ then
		if not self.data.shopEqu[index] then return false
		else data = self.data.shopEqu[index] end
	elseif typ == self.shop_type.car then
		if not self.data.shopCar[index] then return false
		else data = self.data.shopCar[index] end
	elseif typ == self.shop_type.arena then
		if not self.data.shopAre[index] then return false
		else data = self.data.shopAre[index] end
	else return false end
	return true,data
end

function _M:get_buy_max_num(index)
	local num = -1
	local pass,data = self:get_shop(index)
	if not pass then return num end
	num = data.xian
	if num == 0 then num = 9999 end
	if data.only and  data.only >0 then num = data.only end
	return num
end

function _M:is_only(index)
	local pass,data = self:get_shop(index)
	if not pass then return false end
	if not data.only or data.only == 0 then return false end
	return true
end

function _M:check_require(index,vip,stage)
	local pass,data = self:get_shop(index)
	if not pass then return false end
	if not data.require then return true end
	if type(data.require) == "table" then
		--for k,v in pairs(data.require) do
			if data.require[1] == self.require_type.vip and data.require[2] > vip then return false 
			elseif data.require[1] == self.require_type.stage and data.require[2] > stage then return false end
		--end 
	end
	return true
end

function _M:get_hero_data(typ,lv)
	if not lv then lv = 0 end
	local data ={}
	local propin_n =0 
	if typ == 0 then
		--if not self.hero_typ1 then
			self.hero_typ1 ={}
			for i,v in pairs(self.data.shopHero) do
				if (lv >0 and v.level and v.level > 0 and lv >= v.level) or lv == 0 then
					if v.type == 0 then
						local data = v
						data.d_n = 0
						for i,v in pairs(data.dischance) do
							data.d_n = data.d_n + v[2]
						end
						data.p_n = 0
						for i,v in pairs(data.pricetype) do
							data.p_n = data.p_n + v[3]
						end
						propin_n = propin_n + v.propin
						data.propin_n = propin_n
						table_insert(self.hero_typ1,data)
					end
				end
			end
		--end
		data = self.hero_typ1
	elseif typ == 1 then
		--if not self.hero_typ2 then
			self.hero_typ2 ={}
			for i,v in pairs(self.data.shopHero) do
				if (lv >0 and v.level and v.level > 0 and lv >= v.level) or lv == 0 then
					if v.type == 1 then
						local data = v
						data.d_n = 0
						for i,v in pairs(data.dischance) do
							data.d_n = data.d_n + v[2]
						end
						data.p_n = 0
						for i,v in pairs(data.pricetype) do
							data.p_n = data.p_n + v[3]
						end
						propin_n = propin_n + v.propin
						data.propin_n = propin_n
						table_insert(self.hero_typ2,data)
					end
				end
			end
		--end
		data = self.hero_typ2
	end
	return data,propin_n
end

function _M:get_good_hero_data(id)
	local roleMgr = require "manager.roleMgr"
	local frole = roleMgr:get_role(id)
	if not frole then return self:get_hero_data(0) end
	local ids = {}
	local count = 1
	for i,v in ipairs(frole.army.data.battle) do
		if v >0 then 
			for i=1,5 do
				if self.data.armyrelation[v][i] and self.data.armyrelation[v][i].relation_armyvalue then
					for i,v in ipairs(self.data.armyrelation[v][i].relation_armyvalue) do
						--table_insert(ids,v)
						ids[count] = v + 1000
						count = count + 1
					end
				end
			end
		end
	end
	local propin_n =0 
	self.hero_good ={}
	for i,v in pairs(self.data.shopHero) do
		if v.type == 0 then
			for i1,v1 in ipairs(ids) do
				if v.index == v1 then
					local data = v
					data.d_n = 0
					for i,v in pairs(v.dischance) do
						data.d_n = data.d_n + v[2]
					end
					data.p_n = 0
					for i,v in pairs(v.pricetype) do
						data.p_n = data.p_n + v[3]
					end
					propin_n = propin_n + v.propin
					data.propin_n = propin_n
					table_insert(self.hero_good,data)
				end
			end
		end
	end

	if #self.hero_good then return self:get_hero_data(0) end
	return self.hero_good,propin_n
end


function _M:refresh_hero_one(typ,num,id,lv)
	--local data = self:get_hero_data(typ)
	local data = {}
	local data_n = 0
	--ngx.log(ngx.ERR,"typ:",typ," num:",num," id:",id," lv:",lv)
	if num and num >0 and num % self.shop_soldier_get_good_refresh_num == 0 then 
		data,data_n = self:get_good_hero_data(id)
	else data,data_n = self:get_hero_data(typ,lv) end
	if #data <= 0 then data,data_n = self:get_hero_data(0) end

	local r3 = math_random(1,data_n)
	local rd = 0
	local index = pro or 1
	for i,v in ipairs(data) do
		if r3 < v.propin_n then
			rd = i
			break;
		end
		r3 = r3 - v.propin_n
	end
	local rd_data = {}
	--ngx.log(ngx.ERR,"#data:",#data," rd:",rd)
	--ngx.log(ngx.ERR,"data:",cjson.encode(data))
	rd_data.index = data[rd].index
	rd_data.bn = 0
	rd_data.mn =  data[rd].xian
	local r1 = math_random(1,data[rd].d_n)
	local idx = 0
	for i,v in ipairs(data[rd].dischance) do
		if r1 < v[2] then
			idx = i
			break;
		end
		r1 = r1 - v[2]
	end
	if idx == 0 then return false end
	rd_data.dn = idx
	
	local r2 = math_random(1,data[rd].p_n)
	local idx2 = 0
	for i,v in ipairs(data[rd].pricetype) do
		if r2 < v[3] then
			idx2 = i
			break;
		end
		r2 = r2 - v[3]
	end
	if idx2 == 0 then return false end
	rd_data.hn = idx2
	return true,rd_data
end

function _M:refresh(typ,num,id,lv)
	if not num then num =1 end
	local refresh = {}
	if self.shop_type.hero == typ then
		local rd =math_random(1,100)
		--组合为 1道具5士兵碎片20概率  2道具4士兵碎片80概率
		local soldier_num = 4
		if rd > 80 then soldier_num = 5 end
		for i=1,self.shop_soldier_shop_num do
			local refresh_one ={}
			local pass =false
			local good_num = 0
			if i == 4 then good_num = num end 
			if i > soldier_num then	pass,refresh_one = self:refresh_hero_one(1)
			else pass,refresh_one = self:refresh_hero_one(0,good_num,id,lv) end
			if pass then table_insert(refresh,refresh_one)
			else pass,refresh_one = self:refresh_hero_one(0)
				if pass then table_insert(refresh,refresh_one) end
			end
		end
	end
	return refresh
end
return _M