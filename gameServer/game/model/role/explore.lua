-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.explore"
local timetool = require "include.timetool"
local bconfig = require "game.config"
local rankmgr = require "manager.rankMgr"
local task_config = require "game.template.task"
local vip_config = require "game.template.vip"
local open_config = require "game.template.open"
local math_floor = math.floor


local table_insert = table.insert
local math_min = math.min
local math_random = math.random

local _M = model:extends()
_M.class = "role.explore"
_M.push_name  = "explore"
_M.changed_name_in_role = "explore"
_M.attrs = {
	lsp = {0,0,0,0,0,0,0,0,0,0}, --低级进度 
	hsp = {0,0,0,0,0,0,0,0,0,0},--高级进度 
	--n = config.explore_energy_free_max, --体力
	list= {},
	b = 0,   --已购买次数
	lbn = 0,	--低级宝箱开启步数
	hbn = 0,	--高级宝箱开启步数
	hc = 0,  	--高级宝箱抽奖次数
	nt = 0,     --下次体力增加时间
}
--[[self.list={
id	数字	奇遇表id
typ	数字	奇遇类型
bt	数字	奇遇开始时间
n	数字	奇遇宝箱开启次数
sid	数字	关卡id
}]]--

function _M:__up_version()
	_M.super.__up_version(self)
	if not self.data.n then self.data.n =vip_config:get_fun_itmes(self.role,vip_config.type.spirit_max)		 end
	local bchange = false
	local list = {}
	for i,v in ipairs(self.data.list) do
		if type(v) ~= "table" or type(v.id) ~= "number"  then bchange = true
		else table_insert(list,v) end
	end
	if bchange then
		self.data.list = list
	end
end

function _M:init()
	if not self.vip then self.vip = self.role.base:get_vip_level() end
end

function _M:on_vip_up()
	local last = self.vip or 0
	self.data.n  = self.data.n  + vip_config:get_fun_itmes(self.role,vip_config.type.spirit_max) - 
			vip_config:get_fun_itmes_vip(last,vip_config.type.spirit_max)
	self:changed("n")
	self.vip = self.role:get_vip_level()
end
function _M:on_time_up()
	self.data.n = vip_config:get_fun_itmes(self.role,vip_config.type.spirit_max)
	self.data.nt = 0
	self:changed("n")
	self:changed("nt")
end

function _M:update()
	local ltime = timetool:now()
	--if not self.add_energy_time then self.add_energy_time = 0 end
	local max_n = vip_config:get_fun_itmes(self.role,vip_config.type.spirit_max)
	if self.data.n  < max_n and  ltime - self.data.nt >= 0  and self.data.nt > 0 then
			self.data.n  = self.data.n  + 1 + math_floor((ltime - self.data.nt) / config.explore_add_energy_interval )
			self.data.nt = ltime + config.explore_add_energy_interval

			if self.data.n >= max_n then
				self.data.nt = 0 
				self.data.n  = max_n
			end
			self:changed("n")
			self:changed("nt")
	end
	self:check_adventure_list(ltime)

	if self.role.base:get_vip_level() ~= self.vip then 
		self.vip = self.role.base:get_vip_level()
	 end
end

function _M:check_adventure_list(ltime)
	local list ={}
	local change =false
	for k,v in ipairs(self.data.list) do
		local time = 0
		if v.typ == 1 then time = config.explore_typ1_adventure_time 
		elseif v.typ == 2 then time = config.explore_typ2_adventure_time 
		elseif v.typ == 3 then time = config.explore_typ3_adventure_time end
		if ltime - v.bt >= time then change =true
		else table_insert(list,v) end
	end
	if change then
		self.data.list = list
		self:changed("list")
		local data ={}
		data.key="explore"
		local explore_data = {}
		explore_data.list = self.data.list
		data.data = explore_data
		self.role:push("explore.change",data)
	end
end

function _M:can_beging(pos,num)
	if pos < 100 and open_config:check_level(self.role,open_config.need_level.explore_l) then return true 
	elseif pos > 100 and open_config:check_level(self.role,open_config.need_level.explore_h) then return true end
	return false

end
function _M:get_beging_cost(pos,num)
	if self.data.n >= num then return true,{},1 end
	return true,config:get_beging_cost(num),0
end

function _M:create_boss( )
	if not self.role.boss:is_boss_die() then return false end
	local rd = math_random(1,100)
	if rd < config.explore_find_boss_pro and self.role:get_level() >= config.explore_boss_need_level then
		local id = self.role.boss:test()
		self:push("boss.appear",id)
	end
end

function _M:beign_explore(pos,num)
	local adventure = config:create_adventure(pos,num,#self.data.list)
	if adventure and #adventure > 0 then 
		for i,v in ipairs(adventure) do
			table_insert(self.data.list,v)
		end
		self:changed("list")
	end
	if pos > 100 then 
		pos = pos % 100 
		self.data.hsp[pos] = math_min(config.explore_speed_count ,self.data.hsp[pos]  + num )
		self:changed("hsp")
	else 
		self.data.lsp[pos] =math_min(config.explore_speed_count , self.data.lsp[pos]  + num)
		self:changed("lsp")
	end
	self:create_boss()
	return config:get_explore_profit(pos,num)
end

function _M:cost_explore_num(num)
	self.data.n = self.data.n -num
	self.role.tasklist:trigger(task_config.trigger_type.explore,num)
	self:changed("n")

   	if self.data.n + num == vip_config:get_fun_itmes(self.role,vip_config.type.spirit_max) then
   		self.data.nt = timetool:now() + config.explore_add_energy_interval
		self:changed("nt")	
  	end
end

function _M:check_adventure(pos,typ)
	if not self.data.list[pos] then return false end
	if typ and self.data.list[pos].typ ~= typ then return false end
	return true
end
function _M:remove_adventure(pos,ismove)
	if not self.data.list[pos] then return false end
	if not ismove and self.data.list[pos].typ == 3 and self.data.list[pos].n < config.explore_open_box_count then return false end
	local list ={}
	local change =false
	for k,v in ipairs(self.data.list) do
		if k == pos then change =true
		else table_insert(list,v) end
	end
	if change then
		self.data.list = list
		self:changed("list")
		return true
	end
	return false
end

function _M:stage(pos)
	return config:get_adventure_profit(self.data.list[pos].id,1)
end

function _M:get_buy_shop_cost(pos)
	return config:get_buy_shop_cost(self.data.list[pos].id)
end

function _M:buy_shop(pos)
	return config:get_adventure_profit(self.data.list[pos].id,2)
end

function _M:get_heavenbox_cost(pos)
	local diamond = config:get_heavenbox_cost(self.data.list[pos].n)
	self.data.list[pos].n =  self.data.list[pos].n +1
	self:changed("list")
	return {[bconfig.resource.diamond] = diamond}
end

function _M:heavenbox(pos)
	return config:get_adventure_profit(self.data.list[pos].id,3,self.data.list[pos].n)
end

function _M:can_addnum()
	return self.data.b < vip_config:get_fun_itmes(self.role,vip_config.type.buyspirit_num)
end

function _M:get_addnum_cost()
	return config:get_addnum_cost(self.data.b)
end

function _M:addnum()
	self.data.n = self.data.n + config.explore_buy_count_add_energy
	self:changed("n")
	if self.data.n >= vip_config:get_fun_itmes(self.role,vip_config.type.spirit_max)	 then
		self.data.nt = 0
		self:changed("nt")
	end

end

function _M:can_sp_box(pos)
	local count = 0
	local high = false
	if pos > 100 then 
		pos = pos % 100 
		high = true
		count = self.data.hsp[pos]
	else 
		count = self.data.lsp[pos] end
	if count < config.explore_speed_count then return false end
	if high then 
		self.data.hsp[pos] = 0
		self:changed("hsp")
	else 
		self.data.lsp[pos] = 0
		self:changed("lsp")
	end
	return true
end

function _M:get_sp_box_profit(pos)
	return config:get_sp_box_profit(pos)
end

function _M:can_box()
	return true
end

function _M:get_box_cost(typ)
	local cost = config:get_box_cost(typ)
	local en = self.role:check_resource_num(cost)
	if not en then
		if typ == 1 or typ == 2 then cost = config:get_box_cost_diamond(typ,self.data.lbn)
		elseif typ == 3 or typ == 4 then cost = config:get_box_cost_diamond(typ,self.data.hbn) end
	end
	return cost
end

function _M:get_box_profit(typ)
	return config:get_box_profit(typ,self.data.hc)
end


function _M:set_box_step(typ)
	if typ == 1 then 
		self.data.lbn = self.data.lbn +1 
		self:changed("lbn")
	elseif typ == 2 then 
		self.data.lbn = self.data.lbn +2
		self:changed("lbn")
	elseif typ == 3 then 
		self.data.hbn = self.data.hbn +1 
		self.data.hc = self.data.hc +1 
		self:changed("hbn")
		self:changed("hc")
	elseif typ == 4 then 
		self.data.hbn = self.data.hbn +2
		self.data.hc = self.data.hc +10
		self:changed("hbn")
		self:changed("hc")
	end
end


return _M