-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.commander"
local timetool = require "include.timetool"
local CCar = require "game.model.role.car"

local _M = model:extends()
_M.class = "commander"
_M.push_name = "commanders"
_M.changed_name_in_role = "commanders"
_M.attrs = {
	p = "ZHG001",
	j = 0,
	w = "vehicle1",
	ws = {},
	s = {},
	mr = 1,
	mrb = 0,
	mrn = 0,
	cost = {},
	cd={},
	car={},
	lcar=0,
}

function _M:__up_version()
	_M.super.__up_version(self)
	local cds = {}
	for i,v in pairs(self.data.cd) do
		cds[tonumber(i)] = v
	end
	self.data.cd = cds

	local ns = {}
	for i,v in pairs(self.data.s) do
		ns[tonumber(i)] = v
	end
	self.data.s = ns
	local as = config:get_asicskill(self.data.p)
	for i,v in ipairs(as) do
		if not self.data.s[v] then self.data.s[v] = 1 end
	end

	local as = config:get_activeskill(self.data.p)
	for i,v in ipairs(as) do
		if not self.data.s[v] then self.data.s[v] = 0 end
	end

	local vac = config:get_vehicleidkill(self.data.p)
	for i,v in ipairs(vac) do
		if not self.data.s[v] then self.data.s[v] = 0 end
	end

	local pass = config:get_passiveskill(self.data.p)
	for i,v in ipairs(pass) do
		if not self.data.s[v] then self.data.s[v] = 0 end
	end

	--local v = config:get_vehicleskill(self.data.w)
	--if v and not self.data.s[v] then self.data.s[v] = 0 end

	
	local vehicle = config:get_vehicle(self.data.p)
	for i,v in ipairs(vehicle) do
		if not self.data.ws[v] then self.data.ws[v] = 0 end
	end
	
	local new_cars = {}
	for i,v in pairs(self.data.car) do
		i = tonumber(i)
		new_cars[i] = CCar:new(self,v,i,self,"car")
	end
	self.data.car = new_cars
end

function _M:changed(id)
	_M.super.changed(self,id)
	if self.role then
		if self.role.army then
			self.role.army:fight_point_changed()
		end
	end
end

function _M:init()
	self:check_weapon()
end

function _M:get_pid()
	return self.data.p
end

function _M:get_mrank_lev()
	return self.data.mr
end

function _M:get_mrank_bless()
	return self.data.mrb
end

function _M:get_mrank_upcount()
	return self.data.mrn
end

function _M:get_weapon_level(idx)
	return self.data.ws[idx]
end

function _M:check_weapon()
	local bunlock = false
	local bsel = true
	if not self.data.ws[self.data.w] then
		bsel = false
	end
	for i,v in pairs(self.data.ws) do
		if v == 0 then
			if config:canuse_weapon(self,i) then
				self.data.ws[i] = 1
				if not bsel then
					self.data.w = i
					self:changed("w")
					bsel = true
				end
				bunlock = true
			end
		end
	end
	
	if bunlock then
		self:changed("ws")
	end
end

function _M:go_battle()
	self.data.j = 1
	self:changed("j")
end

function _M:out_battle()
	self.data.j = 0
	self:changed("j")
end

function _M:get_level()
	local lev = 0
	if self.role then lev = self.role:get_level() end
	return lev
end

function _M:get_skill_level(id)
	return self.data.s[id]
end

function _M:get_skill_use_time(id)
	return self.data.cd[id] or 0
end

function _M:change_weapon(idx)
	if not self.data.ws[idx] then return end
	self.data.w = idx
	self:changed("w")
	return true
end

function _M:weapon_up(idx)
	if not self.data.ws[idx] then return end
	self.data.ws[idx] = self.data.ws[idx] + 1
	self:changed("ws")
end

function _M:clear_mrank_bless()
	self.data.mrb = 0
	self:changed("mrb")
end

function _M:mrank_up(suc,bless,cost)
	if self.data.mr >= config:get_max_mrank() then return false end
	if suc then
		self.data.mr = self.data.mr + 1
		self.data.mrb = 0
		self.data.mrn = 0
		self:changed("mr")
	else
		self.data.mrb = self.data.mrb + bless
		self.data.mrn = self.data.mrn + 1
	end
	self:append_cost(cost)
	self:changed("mrb")
	self:changed("mrn")
end

function _M:skill_up(id,cost)
	if not self.data.s[id] then return false end
	self.data.s[id] = self.data.s[id] + 1
	self:append_cost(cost)
	self:changed("s")
end


function _M:skill_use(id)
	if not self.data.s[id] then return false end
	self.data.cd[id] = timetool:now()
	self:changed("cd")
end

function _M:skill_clear(id)
	if not self.data.s[id] then return false end
	self.data.cd[id] = 0
	self:changed("cd")
end

function _M:reset_mrank_bless()
	self.data.mrb = 0
	self.data.mrn = 0
	self:changed("mrb")
	self:changed("mrn")
end

function _M:get_car(id)
	if not self.data.car[id] then return false end
	return self.data.car[id]
end

function _M:active_car(id,cost)
	local comcar ={}
	comcar.id = id
	comcar.lv = 1
	comcar.star = 0
	comcar.st = 0
	comcar.exp =0
	self.data.car[id] = CCar:new(self.role,comcar,id,self,"car")
	self.data.car[id]:changed()
	self.data.car[id]:append_cost(cost)
end

function _M:car_level_up(id,add_exp,cost)
	local car = self:get_car(id)
	if not car then return false end
	car:level_up(add_exp,cost)
end

function _M:car_star_up(id,cost )
	self:get_car(id):star_up(cost)
end

function _M:car_strengthen(id,cost )
	self:get_car(id):strengthen(cost)
end

function _M:reborn(id)
	local car = self:get_car(id)
	if not car then return false end
	local profit = car:reborn()
	if self.role and profit then
		self.role:gain_resource(profit)
	end
	return profit
end

function _M:can_use(id)
	if id == 0 then return true end
	local car = self:get_car(id)
	if not car then return false end
	return true
end

function _M:use_car(id)
	self.data.lcar = id
	self:changed("lcar")
end

function _M:inuse()
	return self.data.j ~= 0
end

function _M:get_full_attributes()
	return config:get_full_attributes(self:get_pid(),self.data)
end



return _M