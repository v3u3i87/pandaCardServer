-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local Role = require "include.role"
local config = require "game.config"
local itemConfig = require "game.template.item"
local CSupplybox = require "game.model.supplybox"
local timetool = require "include.timetool"
local cjson = require "include.cjson"
local s_sub = string.sub

local _M = Role:extends()
_M.all_attrs = config.role.attributes
_M.dead_time = config.role.dead_time

function _M:login(wb)
	_M.super.login(self,wb)
	if not self.supplybox then self.supplybox = CSupplybox:new(self) end
	if self.client_num == 1 then
		--self.extend:calc_offline()
		self.supplybox:login()
		self.mailbox:receive_from_mailMgr()
	end
end

function _M:logout()
	_M.super.logout(self)
	if self.client_num < 1 then
		self.extend:offline(timetool:now())
		if self.supplybox then self.supplybox:logout() end
	end
end

function _M:push(task,data)
	if _M.super.push(self,task,data) then 
		if type(data) == "table" and data.key and data.key == "boss" and task ~= "boss.change" then 
			local msg = {
				task = "boss.change",
				status = 0,
				time = timetool:now(),
				data = data
			}
			self.client:push(cjson.encode(msg))
		end
		return true
	else return false end
end

function _M:update()
	for i,v in pairs(config.update_obj) do
		local upcount = self.extend:update(i)
		if upcount > 0 then
			self[v.data][v.fun](self[v.data],upcount)
		end
	end

	if self.supplybox then
		local box = self.supplybox:test()
		if box then
			self:push("supplybox.appear",box)
		end
	end

	for i,v in ipairs(self.all_attrs) do
		if self[v] and self[v].update then 
			self[v]:update() 
		end
	end
	self:on_time_up()
end

function _M:get_level()
	return self.base:get_level()
end

function _M:get_vip_level()
	return self.base:get_vip_level()
end

function _M:get_stage()
	return self.base:get_stage_int()

end

function _M:get_create_time()
	return self.extend:get_create_time()
end

function _M:get_fight_point()
	local point = self.base:get_fight_point()
	if point == 0 then point = self.army:get_fight_point() end
	return point
end

function _M:get_union_name()
	return ""
end

function _M:get_damage()
	return self.boss:get_damage()
end

function _M:get_exploit()
	return self.boss:get_exploit()
end

function _M:get_arena()
	return self.arena:get_arena()
end

function _M:get_online()
	return self:is_online() and 1 or 0
end

function _M:get_simple_info()
	local info = {
		id = self.id,
		name = self.name,
		lev = self.base:get_level(),
		atk = self:get_fight_point(),
		un = self:get_union_name(),
		on = self:get_online(),
		ont= self:get_last_request_time(),
		da = self:get_damage(),
		ex = self:get_exploit(),
		ar = self:get_arena(),
		np = self.both:get_both_np(),
		sn = self:get_stage()
	}
	return info
end

function _M:get_rank_info(rt)
	if self:is_dead() then return nil end
	local info = {}
	info.id = self.id
	info.data = self:get_simple_info()
	info.pt = nil
	if rt == config.rank_type.level then
		info.pt = self:get_level()
	elseif rt == config.rank_type.fight_point then
		info.pt = self:get_fight_point()
	elseif rt == config.rank_type.stage then
		info.pt = self:get_stage()
	elseif rt == config.rank_type.damage then
		info.pt = self:get_damage()
	elseif rt == config.rank_type.exploit then
		info.pt = self:get_exploit()
	elseif rt == config.rank_type.arena then
		info.pt = self:get_arena()
	elseif rt == config.rank_type.both then
		info.pt = self.both:get_both_np()
	else
		if rt and s_sub(rt,1,7) == "soldier" then
			local sid = tonumber(s_sub(rt,9))
			local soldier = self.soldiers:get(sid)
			if soldier then
				info.pt = soldier:get_fight_point()
			end
		end
	end
	return info
end

function _M:receive_mail(mail)
	local rt = self.mailbox:receive(mail)
	self.mailbox:push_update()
	return rt
end

function _M:open_supplybox()
	if not self.supplybox then return fasle end
	return self.supplybox:open()
end

function _M:create_cost(data)
	if type(data) ~= "table" then return false,{} end

	local cost = {}
	for id,num in pairs(data) do
		local t = itemConfig:get_type(id)

		if t == itemConfig.type.virtual then
			if id == config.resource.money then
				cost.money = (cost.money or 0) + num
			elseif id == config.resource.diamond then
				cost.diamond = (cost.diamond or 0) + num
			elseif id == config.resource.exp then
				cost.exp = (cost.exp or 0) + num
			else
				cost.virtual = cost.virtual or {}
				cost.virtual[id] = (cost.virtual[id] or 0) + num
			end
		elseif t == itemConfig.type.soldier then
			cost.soldiers = cost.soldiers or {}
			cost.soldiers[id] = (cost.soldiers[id] or 0) + num
		elseif t == itemConfig.type.equipment or t == itemConfig.type.accessory then
			cost.depot = cost.depot or {}
			cost.depot[id] = (cost.depot[id] or 0) + num
		elseif t == itemConfig.type.soldierfrag or t == itemConfig.type.material or t == itemConfig.type.property or 
				t == itemConfig.type.equipmentfrag or t == itemConfig.type.accessoryfrag or t == itemConfig.type.awaken 
				or t == itemConfig.type.soldierillustrated  or t == itemConfig.type.box then
			cost.knapsack = cost.knapsack or {}
			cost.knapsack[id] = (cost.knapsack[id] or 0) + num
		elseif t == itemConfig.type.commander then
			cost.commanders = cost.commanders or {}
			cost.commanders[id] = (cost.commanders[id] or 0) + num
		end
	end
	return true,cost
end

function _M:check_resource_num(cost)
	local enough = true
	enough,cost = self:create_cost(cost)
	if not enough then return false,{} end

	cost.diamond = cost.diamond or 0
	if cost.diamond > self.base:get_diamond() then
		enough = false
	end

	if cost.money then
		local money = self.base:get_money()
		if cost.money > money then
			enough = false
			cost.diamond = cost.diamond + (cost.money - money)*100
		end
	end

	if cost.virtual then
		local virtual = {}
		for k,v in pairs(cost.virtual) do
			virtual[k] = v
			local e,n = self.virtual:check_num(k,v)
			if not e then
				enough = false
				cost.diamond = cost.diamond + n * itemConfig:get_diamond_cost(k)
				virtual[k] = v - n
				if virtual[k] == 0 then virtual[k] = nil end
			end
		end
		cost.virtual = virtual;
	end

	if cost.knapsack then
		local knapsack = {}
		for k,v in pairs(cost.knapsack) do
			knapsack[k] = v
			local e,n = self.knapsack:check_num(k,v)
			if not e then
				enough = false
				cost.diamond = cost.diamond + n * itemConfig:get_diamond_cost(k)
				knapsack[k] = v - n
				if knapsack[k] == 0 then knapsack[k] = nil end
			end
		end
		cost.knapsack = knapsack;
	end
	
	if cost.soldiers then
		local soldiers = {}
		for pid,num in pairs(cost.soldiers) do
			soldiers[pid] = num
			local soldier = self.soldiers:get(pid)
			local n = 0
			if soldier then n = soldier:get_num() end
			if n < num then
				enough = false
				cost.diamond = cost.diamond + (num - n) * itemConfig:get_diamond_cost(pid)
				soldiers[pid] = n
				if soldiers[pid] == 0 then soldiers[pid] = nil end
			end
		end
		cost.soldiers = soldiers
	end
	
	if cost.depot then
		local depot = {}
		for pid,num in pairs(cost.depot) do
			local n,items = self.depot:get_items(pid,1,0)
			if n < num then
				enough = false
				cost.diamond = cost.diamond + (num - n) * itemConfig:get_diamond_cost(pid,1,0)
			end
			local i = 0
			for id,item in pairs(items) do
				depot[id] = item
				i = i + 1
				if i == num then break; end
			end
		end
		cost.depot = depot
	end
	
	if cost.commanders then
		local commanders = {}
		for pid,num in pairs(cost.commanders) do
			local n,items = self.commanders:get_commanders(pid,1)
			if n < num then
				enough = false
				cost.diamond = cost.diamond + (num - n) * itemConfig:get_diamond_cost(pid,1)
			end
			for id,item in pairs(items) do
				commanders[id] = item
			end
		end
		cost.commanders = commanders
	end
	
	return enough,cost.diamond,cost
end

function _M:consume_resource(cost)
	if not cost then return false end
	if cost.diamond and cost.diamond > 0 then self.base:add_diamond(0-cost.diamond) end
	if cost.money and cost.money > 0 then self.base:add_money(0-cost.money) end
	if cost.virtual then self.virtual:consume_more(cost.virtual) end
	if cost.knapsack then self.knapsack:consume_more(cost.knapsack) end
	if cost.depot then self.depot:consume_more(cost.depot) end
	if cost.soldiers then self.soldiers:consume_more(cost.soldiers) end
	if cost.commanders then self.commanders:consume_more(cost.commanders) end
end

function _M:gain(id,num)
	local t = itemConfig:get_type(id)
	if t == itemConfig.type.virtual then
		if id == config.resource.money then
			self.base:add_money(num)
		elseif id == config.resource.diamond then
			self.base:add_diamond(num)
		elseif id == config.resource.exp then
			self.base:add_exp(num)
		elseif id == config.resource.star then
			self.base:add_exp(num)
		else
			self.virtual:gain(id,num)
		end
	elseif t == itemConfig.type.soldier then
		self.soldiers:conscripts(id,num)
	elseif t == itemConfig.type.equipment or t == itemConfig.type.accessory then
		local CItem = require "game.model.role.item"
		for i = 1,num do
			self.depot:gain(CItem:new(nil,{p=id}))
		end
	elseif t == itemConfig.type.soldierfrag or t == itemConfig.type.material or t == itemConfig.type.property 
		or t == itemConfig.type.equipmentfrag or t == itemConfig.type.accessoryfrag or t == itemConfig.type.awaken 
		or t == itemConfig.type.soldierillustrated  or t == itemConfig.type.box then
		self.knapsack:gain(id,num)
	elseif t == itemConfig.type.commander then
		local CCommander = require "game.model.role.commander"
		for i = 1,num do
			self.commanders:conscripts(CCommander:new(nil,{p=id}))
		end
	end
end

function _M:gain_resource(profit)
	for id,num in pairs(profit) do
		self:gain(id,num)
	end
end

function _M:get_member_by_channel(channel)
	if type(channel) ~= "number" then return false end
	if channel > 0 then return {channel} end
	if channel == -1 then return 'all' end
	return false
end

function _M:on_level_up()
	for i,v in ipairs(self.all_attrs) do
		if self[v].on_level_up then 
			self[v]:on_level_up(self:get_level()) 
		end
	end
end

function _M:on_vip_up()
	for i,v in ipairs(self.all_attrs) do
		if self[v].on_vip_up then 
			self[v]:on_vip_up(self.base:get_vip_level()) 
		end
	end
end

function _M:on_time_up()
	if self.base and self.base:is_time_updata(0) then
 		for i,v in ipairs(self.all_attrs) do
			if self[v].on_time_up then 
				self[v]:on_time_up() 
			end
		end
	end
end

function _M:virtula_add_count(id,num)
	for i,v in ipairs(self.all_attrs) do
		if self[v].virtula_add_count and self[v].virtual_id == id then 
			self[v]:virtula_add_count(num) 
		end
	end
end

function _M:get_battle_info()
	local data = {}
	data.id = self:get_id()
	data.name = self.name
	data.base= {lev=self:get_level()}
	data.commanders = self.commanders:get_use_data()
	data.soldiers = self.soldiers:get_use_data()
	data.depot = self.depot:get_use_data()
	data.army = self.army:get_client_data()
	return data
end


function _M:get_cid()
	if not self.cid then 
		local mysql = require "include.mysql"
		local u_config = require "login.config"
		local con = mysql:new(u_config.user_db.ip,u_config.user_db.port,u_config.user_db.user,u_config.user_db.pw,u_config.user_db.db)	
		local sql = "SELECT * FROM " .. u_config.user_db.table .. " WHERE uid=" .. self:get_id()
		local result,errmsg = con:query(sql)
		if #result == 1 then
			self.cid = result[1].cid
		end
	end
	return self.cid or 0
end
return _M