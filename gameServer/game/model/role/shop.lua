-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.shop"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local task_config = require "game.template.task"
local vip_config = require "game.template.vip"
local math_floor = math.floor
local table_insert = table.insert

local _M = model:extends()
_M.class = "role.shop"
_M.push_name  = "shop"
_M.changed_name_in_role = "shop"
_M.attrs = {
	blist ={},--	role_blist_shops	商店数据表
	slist ={},	--	role_slist_shops	士兵商店
	fn 	=config.shop_soldier_refresh_free,	--数字	士兵商店免费次数
	rn	=0,	--数字	士兵商店已刷次次数
	at	=0,	--数字	士兵商店免费次数下次增加时间
	arn = 0 ,--总刷新
}

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.vip then self.vip = 0	end
	if not self.level then self.level = 0	end
	if not self.fn_max then self.fn_max = vip_config:get_fun_itmes(self.role,vip_config.type.heroshop_max_r_num) end

	local cds = {}
	for i,v in pairs(self.data.blist) do
		cds[tonumber(i)] = v
	end
	self.data.blist = cds

	cds = {}
	for i,v in pairs(self.data.slist) do
		cds[tonumber(i)] = v
	end
	self.data.slist = cds

end

function _M:on_vip_up()
	local last = self.vip or 0
	self.fn_max = vip_config:get_fun_itmes(self.role,vip_config.type.heroshop_max_r_num)
	self.vip = self.role:get_vip_level()
end

function _M:on_time_up()
	self.data.fn =  config.shop_soldier_refresh_free
	self.data.rn =  0
	self.data.at = 0
	self:changed("fn")
	self:changed("rn")
	self:changed("at")

	local blist = {}
	for i,v in pairs(self.data.blist) do
		if config:is_only(v.index) then blist[v.index] = v end
	end
	self.data.blist = blist
	self:changed("blist")

end

function _M:update(vip)
	local ltime = timetool:now() 
	if self.data.fn < config.shop_soldier_refresh_free and ltime - self.data.at >= 0 and self.data.at > 0 then 
		self.data.at = ltime + config.interval_time
		self.data.fn = self.data.fn + 1 + math_floor((ltime - self.data.at) / config.interval_time )
		if self.data.fn >= config.shop_soldier_refresh_free then
			self.data.at = 0
			self.data.fn  = config.shop_soldier_refresh_free
		end
		self:changed("fn")
		self:changed("at")
	end
	if self.vip ~= vip then self.vip = vip end
	if # self.data.slist < 6 then 
		self.data.slist = config:refresh(config.shop_type.hero,0,0,self.role:get_level())
		self:changed("slist")
	end
end

function _M:find_slist_index_by_id(id)
	local index = 0
	for i,v in ipairs(self.data.slist) do
		if id == v.index then index = i break	end
	end
	return index
end


function _M:can_buy(index,count,pos)
	if not config:get_shop(index) then return false end
	if not config:check_require(index,self.role.base:get_vip_level(),self.role.base:get_stage_int()) then return false end
	local max_num = config:get_buy_max_num(index)
	if count < 0 then return false end
	local typ = config:get_type(index)
	if typ ~= config.shop_type.hero  and  max_num < count then return false end
	if typ == config.shop_type.common or typ == config.shop_type.car or typ == config.shop_type.equ or typ == config.shop_type.arena then
		if not self.data.blist[index] then return true,typ end
		if self.data.blist[index].bn + count > max_num then return false end
	elseif typ == config.shop_type.hero then
		if not pos then pos = 1 end
		--index = self:find_slist_index_by_id(index)
		if not self.data.slist[pos] then return false end
		if not self.data.slist[pos].mn then self.data.slist[pos].mn = 1 end
		if self.data.slist[pos].bn + count > self.data.slist[pos].mn then return false end
	else return false end
	return true,typ
end

function _M:get_buy_cost(index,count,typ)
	local cost ={}
	local pass,data = config:get_shop(index)
	if typ == config.shop_type.hero then
		index = self:find_slist_index_by_id(index)
		local num = data.dischance[ self.data.slist[index].dn ][1] or 1
		local pricetype_id =data.pricetype[ self.data.slist[index].hn ][1]
		local pricetype_num =data.pricetype[ self.data.slist[index].hn ][2]
		cost[pricetype_id] = pricetype_num * num * count
	else cost= bconfig:change_cost_num(data.pricetype,count) end
	return cost
end

function _M:buy(index,count,typ,pos)
	local profit ={}
	local pass,data = config:get_shop(index)
	local num = data.discount  * count

	self.role.tasklist:trigger(task_config.trigger_type.shop_buy,count)
	if typ == config.shop_type.hero then
		--index = self:find_slist_index_by_id(index)
		num = (data.dischance[ self.data.slist[pos].dn ][1] or 1 ) * num 
		self.data.slist[pos].bn = (self.data.slist[pos].bn or 0) + count
		self:changed("slist")
	elseif typ == config.shop_type.common or typ == config.shop_type.car or typ == config.shop_type.equ or typ == config.shop_type.arena then
		if not self.data.blist[index] then
			local onelist ={}
			onelist.index = index
			onelist.bn = 0
			self.data.blist[index] = onelist
		end
		self.data.blist[index].bn = (self.data.blist[index].bn or 0) + count
		self:changed("blist")
	end
	profit[data.id] = num
	return profit
end


function _M:can_refresh(typ)
	if typ == config.shop_type.hero and self.fn_max > self.data.rn then return true end
	return false
end

function _M:get_refresh_cost(typ)
	local cost ={}
	if typ == config.shop_type.hero then
		if self.data.fn > 0 then return true,{} end
		cost[config.shop_soldier_refresh_id1]  = config.shop_soldier_refresh_id1_num
		local en =nil
		local diamond =0
		en,diamond,cost = self.role:check_resource_num(cost)
		if not en then
			cost[config.shop_soldier_refresh_id2]  = config.shop_soldier_refresh_id2_num
			en,diamond,cost = self.role:check_resource_num(cost)
			if not en then return false,{}
			else return true,cost end
		else
			return true,cost
		end
	end
	return false
end

function _M:refresh(typ)
	if typ == config.shop_type.hero then
		if self.data.fn > 0 then
			self.data.fn = self.data.fn - 1
			if self.data.fn + 1 == config.shop_soldier_refresh_free then
				self.data.at = timetool:now() + config.interval_time
			end
			self:changed("at")
			self:changed("fn")
		end
		self.data.rn = self.data.rn + 1
		self.data.arn = self.data.arn + 1
		self:changed("rn")

		local lv = 0
		if not self.last_lv or self.last_lv ~= self.role:get_level() then lv = self.role:get_level() end
		self.last_lv = self.role:get_level()
		self.data.slist = config:refresh(typ,self.data.rn,self.role:get_id(),lv)
		self:changed("slist")
		return self.data.slist
	end
end

function _M:get_shop_refresh()
	return self.data.arn or 0
end

return _M