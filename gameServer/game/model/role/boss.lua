-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.boss"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local rankmgr = require "manager.rankMgr"
local task_config = require "game.template.task"
local vip_config = require "game.template.vip"
local open_config = require "game.template.open"
local table_insert = table.insert

local _M = model:extends()
_M.class = "role.boss"
_M.push_name  = "boss"
_M.changed_name_in_role = "boss"
_M.virtual_id = 23
_M.attrs = {
	id = 0,
	shop = {
		ep = {0,0,0,0,0,0},	--shop.index
		n = {1,1,1,1,1,1},	--数量,默认为1
		b ={1,1,1,1,1,1},	--[1,1,1,1,1,1] 1:pricetype[1],2:pricetype[2]
		--fn = config.boss_refresh_free,				--免费刷新次数
		sn = config.boss_refresh_max,				--剩余刷新次数
		--rn = 0 ,			--已购买刷新次数
		st = 0,				--上次刷次时间
	},
	da = 0, --总伤害值
	ex = 0, --总功勋值
	cn = config.boss_challenge_free_max,	--剩余挑战次数
	bn = 0 ,--购买挑战次数
	l = 0,  --当前boss伤害值
	t = 0, -- 当前boss出现时间
	exg ={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,},
	list ={},
	at =0, --增加次数的时间
}

--[[_M.list ={
id	数字	boss id
pn	数字	发启人名字
hp	数字	当前伤害值
bt	数字	boss开启时间
bc	数字	这次攻击开始时间
}
]]--

function _M:__up_version()
	_M.super.__up_version(self)
	if self.data.shop.ep[1] == 0 then self:refresh_item() end
	if not self.list then self.list = {} end
	if self.data.shop.sn < 0 then   self.data.shop.sn = config.boss_refresh_max end
	if not self.data.shop.fn then self.data.shop.fn = vip_config:get_fun_itmes(self.role,vip_config.type.pokedexshop_num) end

end
--
function _M:on_time_up()
	self.data.cn  = config.boss_challenge_free_max
	self.data.shop.fn  = vip_config:get_fun_itmes(self.role,vip_config.type.pokedexshop_num)
	self.data.shop.sn = config.boss_refresh_max
	self.data.at = 0
	self.data.da  = 0
	self.data.ex  = 0
	for i,v in ipairs(self.data.exg) do
		self.data.exg[i] = 0
	end
	self:changed("cn")
	self:changed("shop")
	self:changed("fn")
	self:changed("at")
	self:changed("da")
	self:changed("ex")
	self:changed("exg")
end


function _M:on_vip_up()
	local last = self.vip or 0
	self.data.shop.fn  = self.data.shop.fn  + vip_config:get_fun_itmes(self.role,vip_config.type.pokedexshop_num) - 
			vip_config:get_fun_itmes_vip(last,vip_config.type.pokedexshop_num)
	self:changed("shop")
	self.vip = self.role:get_vip_level()
end

function _M:virtula_add_count(num)
	self.data.cn = self.data.cn + num
	self:changed("cn")
end

function _M:clear_data()
	self.data.da  = 0
	self.data.ex  = 0
	self:changed("da")
	self:changed("ex")
	rankmgr:remove(bconfig.rank_type.damage,self.role)
	rankmgr:remove(bconfig.rank_type.exploit,self.role)
end

function _M:get_damage( )
	return self.data.da
end

function _M:get_exploit( )
	return self.data.ex
end

function _M:update()
	local ltime = timetool:now()
	if not self.add_refresh_time then self.add_refresh_time = 0 end
	if self.data.cn  < config.boss_challenge_free_max and  
		ltime - self.data.at > 0 then
			self.data.cn  = self.data.cn  + 1
			self.data.at = ltime + config.boss_add_challenge_interval 
			if self.data.cn >= config.boss_challenge_free_max then
				self.data.at = 0
			end
			self:changed("cn")
	end
	--[[if self.data.shop.sn >0 and self.data.shop.fn < config.boss_refresh_free and  
		ltime - self.add_refresh_time >= config.boss_add_refresh_interval then
			self.data.cn  = self.data.cn  + 1
			self:changed("cn")
			self.add_refresh_time = ltime
	end]]--
	self:check_boss_list(ltime)
	--[[if self.data.da >0 or self.data.ex >0 then
		local hour = timetool:get_hour()
		if hour == 4 then self:clear_data() end
	end]]--
end

function _M:check_boss_list(ltime)
	local list ={}
	local change =false
	for k,v in ipairs(self.data.list) do
		if ltime - v.bt >= config.boss_time then 
			change =true
			if v.id == self.data.id then self.data.id = 0 end
		else table_insert(list,v) end
	end
	if change then
		self.data.list = list
		local data ={}
		data.key="boss"
		local boss_data = {}
		boss_data.list = self.data.list
		boss_data.id = self.data.id
		data.data = boss_data
		self.role:push("boss.change",data)
	end
end


function _M:test( )
--	ngx.log(ngx.ERR,"ex:",self.data.ex .. "da:" ,self.data.da)
	local ltime = timetool:now() 
	if self.data.id == 0 or ltime - self.data.t > 3600 then  --or  ltime - self.data.t > 3600
		self.data.id = config:get_rand_boss()
		--self.data.id = 7 
		self.data.l = 0
		self.data.t = ltime 
		--self:changed("id")
		self.list.id = self.data.id
		self.list.pn = self.role:get_name()
		self.list.hp = 0
		self.list.bt = self.data.t
		self.list.bc = 0
		table_insert(self.data.list,self.list)
		self:changed("list")

	else return false end
	return self.data.id
end

function _M:is_begin(id,pn)
	if not  open_config:check_level(self.role,open_config.need_level.boss) then return false end

	local btime = self:get_challage_begin_time(id,pn)
	if btime < 0 then return false end
	if timetool:now() -  btime < config.boss_challage_time then return false end
	return true
end

function _M:is_boss_die()
	if self.data.shop.ep[1] == 0 then self:refresh_item() end
	if self.data.id == 0 then return true end
	local boss_hp = config:boss_hp(self.data.id)

	if boss_hp <= self.data.l then 
		self:remove_boss(self.data.id)
		self.data.id = 0
		self.data.l = 0
		self:changed("id")
		self:changed("l")
		self:send_mail(self.data.id)
		return true
	end
	return false
end

function _M:remove_boss(id)
	local list ={}
	for k,v in ipairs(self.data.list) do
		if v.id ~= id then table_insert(list, v)
		else v = nil end
	end
	self.data.list = list
	local cjson = require "include.cjson"
	ngx.log(ngx.ERR,"self.data.list:",cjson.encode(self.data.list))
end

function _M:get_challage_begin_time(id,pn)
	local time = -1
	for k,v in ipairs(self.data.list) do
		if (v.id == id and pn and v.pn == pn ) or 
			(v.id == id and not pn) then 
			time = v.bc or 0 
			break
		end
	end
	return time
end

function _M:set_challage_begin_time(id,pn)
	for k,v in ipairs(self.data.list) do
		if (v.id == id and pn and v.pn == pn ) or 
		(v.id == id and not pn) then 
			v.bc =  timetool:now()
			break
		end
	end
	self:changed("list")
end

function _M:get_boss_begin_time(id)
	local time = 0
	for k,v in ipairs(self.data.list) do
		if (v.id == id and pn and v.pn == pn ) or 
		(v.id == id and not pn) then 
			time = v.bt
			break
		end
	end
	return time
end


function _M:check_begin_time(id,pn)
	return self:get_challage_begin_time(id,pn) > 0 
end


function _M:can_challenge(id,typ)
	if not  open_config:check_level(self.role,open_config.need_level.boss) then return false end

	if self:is_boss_die() then return false end
	if id ~= self.data.id or self.data.id == 0 then return false end
	local cost_num = config:get_challage_cost_num(typ)

	if cost_num > self.data.cn then return false end
	return true,cost_num
end

function _M:can_other_challenge(id,typ)
	local cost_num = config:get_challage_cost_num(typ)
	if cost_num > self.data.cn then return false end
	return true,cost_num
end

function _M:add_boss_damage(id,damage)
	local pn = self.role:get_name()
	for k,v in ipairs(self.data.list) do
		if v.id == id and pn and v.pn == pn  then 
			v.hp = v.hp + damage
			break
		end
	end
	self:is_boss_die()
end


function _M:challenge(damage,id)
	local exploit = config:get_challage_add_exploit(damage)


	self.data.da = self.data.da + damage
	self.data.ex = self.data.ex + exploit
	self.data.l = self.data.l + damage
	self:changed("l")
	self:changed("da")
	self:changed("ex")
	self.role.tasklist:trigger(task_config.trigger_type.boss_challenge,1)
	rankmgr:update(bconfig.rank_type.damage,self.role)
	rankmgr:update(bconfig.rank_type.exploit,self.role)
	if config:boss_hp(self.data.id) <= self.data.l then
		self.role.tasklist:trigger(task_config.trigger_type.boss_challenge_kill,1)
	end
	self:add_boss_damage(id,damage)
	self:changed("list")
end

function _M:other_challenge(damage)
	local exploit = config:get_challage_add_exploit(damage)
	self.data.da = self.data.da + damage
	self.data.ex = self.data.ex + exploit
	self:changed("da")
	self:changed("ex")
	rankmgr:update(bconfig.rank_type.damage,self.role)
	rankmgr:update(bconfig.rank_type.exploit,self.role)
	if config:boss_hp(self.data.id) <= self.data.l then self.data.k = self.data.k +1 end
	self:changed("list")
end

function _M:add_damage(damage,id)
	self.data.l = self.data.l + damage
	self:changed("l")
	self:add_boss_damage(id,damage)
end

function _M:cost_challenge(num)
	self:use_virtaul(num)
	self.data.cn = self.data.cn - num
	self:changed("cn")
	if self.data.at <= 0 then self.data.at = timetool:now() + config.boss_add_challenge_interval end
end

function _M:get_challenge_profit(id)
 	return config:get_profit(id)
end

function _M:can_get_one_explot(id)
	local list = {}


	if not self.data.exg[id] or self.data.exg[id] ~= 0 or not config:can_get_explot(id,self.data.ex) then return false end
	table_insert(list, id)
	return list
end

function _M:can_get_all_explot()
	local list = {}
	for k,v in ipairs(self.data.exg) do
		if v == 0  and config:can_get_explot(k,self.data.ex) then table_insert(list, k)	end
	end
	return list
end

function _M:get_explot(list)
	local profit = {}
	for k,v in ipairs(list) do
		local pass,profitone= config:get_explot(v)
		for id,num in pairs(profitone) do
			profit[id] = (profit[id] or 0)	+ num
		end
		self.data.exg[v] = 1
	end
	self:changed("exg")
	return profit
end

function _M:challenge_end(id,pn)
	for k,v in ipairs(self.data.list) do
	 if (v.id == id and pn and v.pn == pn ) or 
		(v.id == id and not pn) then 
			v.bc = 0
			break
		end
	end
	self:changed("list")
end

function _M:can_buy_challenge(num)
	if not  open_config:check_level(self.role,open_config.need_level.boss_shop) then return false end

	return self.data.bn + num <= vip_config:get_fun_itmes(self.role,vip_config.type.dekaron_num)
end

function _M:buy_challenge(num )
	local diamond = 0
	for i=1,num do
		diamond = diamond + config:get_diamond(self.data.bn)
	end
	return true,{ [bconfig.resource.diamond] = diamond }
end

function _M:add_challenge_count(num )
	if not num then num = 1 end
	self.data.bn = self.data.bn + num
	self.data.cn = self.data.cn + num
	self:changed("bn")
	self:changed("cn")
end

function _M:can_refresh_item( )
	if self.data.shop.fn > 0 then return true,{},1 end
	local cost = config:get_refresh_cost(1)
	local en =nil
	local diamond =0
	en,diamond,cost = self.role:check_resource_num(cost)
	if not en then
		cost = config:get_refresh_cost(2)
		en,diamond,cost = self.role:check_resource_num(cost)
		if not en then return false,{}
		else return true,cost,0 end
	else return true,cost,0 end
end

function _M:refresh_item(num)
	local ep,b,n = config:refresh_item()
	self.data.shop.ep = ep
	self.data.shop.b = b
	self.data.shop.n = n
	self.data.shop.st = timetool:now() 
	self.data.shop.sn = self.data.shop.sn -1
	if num and num >0 then 	self.data.shop.fn = self.data.shop.fn -1 end
	if not self.add_refresh_time then self.add_refresh_time = timetool:now()  end
	self:changed("shop");
end


function _M:can_buy_item(pos)
	if  self.data.shop.n[pos]  >= 1 then return true end
	return false
end

function _M:get_can_buy_cost(index)
	return config:get_can_buy_cost( self.data.shop.ep[index],self.data.shop.b[index])
end

function _M:buy_item(index)
	self.data.shop.n[index] = self.data.shop.n[index] -1
	self:changed("shop")
	self.role.tasklist:trigger(task_config.trigger_type.shop_buy,1)

	return 	config:get_buy_item(self.data.shop.ep[index] )
end

function _M:get_share_list(id,typ)
	local role_list = {}
	local boss_info = {}
	boss_info.id = id
	boss_info.pn = self.role:get_name()
	boss_info.hp = self.data.l
	boss_info.bt = self:get_boss_begin_time(id,pn)
	boss_info.bc = 0
	self.list.bc = 0
	if self.data.id ~= id then return false end
	if typ == 1 then
		role_list = self.role.friends:get_all_role()
	elseif typ == 2 then
	end
	return true,role_list,boss_info
end

function _M:add_boss_list(boss_info)
	table_insert(self.data.list,boss_info)
	self:changed("list")
end

function _M:send_mail(id)
	local mail = {
		t = 1,
		s = 0,
		h = "敌将来袭奖励",
		c = "战场之地，瞬息万变，司令部感谢你及时侦查到敌将的动向，以下给予您的奖励，司令部期待你的表现！",
		p = config:get_boss_profit(id) or {},
	}
	self.role:receive_mail(CMail:new(nil,mail))
end


return _M