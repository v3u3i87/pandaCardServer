-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.config"
local itemConfig = require "game.template.item"
local armyConfig = require "game.template.army"
local rankMgr = require "manager.rankMgr"
local open_config = require "game.template.open"
local cjson = require "include.cjson"

local table_insert = table.insert
local int = math.floor


local _M = model:extends()
_M.class = "role.army"
_M.push_name  = "army"
_M.changed_name_in_role = "army"
_M.attrs = {
	commander = 101,
	battle = {0,-1,-1,-1,-1,-1,-1,-1},
	equips = {{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0},{0,0,0,0,0,0}},
	companion = {-1,-1,-1,-1,-1,-1,-1,-1},
	em = {1,2,3,4,5,6,7,8},
}

function _M:__up_version()
	_M.super.__up_version(self)
end

function _M:init()
	if self.data.battle[1] == 0 and self.role.soldiers then
		self:go_battle(1003,1)
	end
	self:on_level_up(self.role:get_level())
end

function _M:on_vip_up()
	local last = self.vip or 0
	self.vip = self.role:get_vip_level()
	if not self.data.companion[9] and open_config:check_vip(self.role,open_config.need_vip.army_unlock_companion) then
		self.data.companion[9] = -1
		self.data.companion[10] = -1
		self:changed("companion")
	end 
end


function _M:changed(id)
	_M.super.changed(self,id)
	--self:fight_point_changed()
end

function _M:fight_point_changed()
	self.fp_changed = true
	if self.role then
		rankMgr:update(config.rank_type.fight_point,self.role)
	end
end

function _M:unlock_battle_pos(pos)
	if self.data.battle[pos] ~= -1 then return end
	self.data.battle[pos] = 0
	self:changed("battle")
end

function _M:unlock_companion_pos(pos)
	if self.data.companion[pos] ~= -1 then return false end
	self.data.companion[pos] = 0
	self:changed("companion")
	return true
end

function _M:check_unlock_companion_pos(pos)
	if	armyConfig:can_unlock_companion(pos,self.role:get_level()) and self.data.companion[pos] == -1 then
		return true,armyConfig:get_unlock_companion_cost(pos)
	end
	return false,{}
end

function _M:set_unlock_companion_pos(pos)
	self.data.companion[pos] = 0
	self:changed("companion")
end

function _M:can_fill(typ,pos)
	if self.data[typ] and self.data[typ][pos] and self.data[typ][pos] ~= -1 then return true end
	return false
end

function _M:go_battle(id,pos)
	if not self:can_fill("battle",pos) then return false end
	local soldier = self.role.soldiers:get(id)
	if not soldier then return false end
	local old_soldier_id = self.data.battle[pos]
	if old_soldier_id ~= 0 then
		local old_soldier = self.role.soldiers:get(old_soldier_id)
		if old_soldier then old_soldier:out_battle() end
	end
	self.data.battle[pos] = id
	soldier:go_battle()
	self:changed("battle")
	return true
end

function _M:go_companion(id,pos)
	if not self:can_fill("companion",pos) then return false end
	local soldier = self.role.soldiers:get(id)
	if not soldier then return false end
	local old_soldier_id = self.data.companion[pos]
	if old_soldier_id ~= 0 then
		local old_soldier = self.role.soldiers:get(old_soldier_id)
		if old_soldier then old_soldier:out_battle() end
	end
	self.data.companion[pos] = id
	soldier:go_battle()
	self:changed("companion")
	return true
end

function _M:out_companion(pos)
	if not self:can_fill("companion",pos) then return false end
	local old_soldier_id = self.data.companion[pos]
	if old_soldier_id ~= 0 then
		local old_soldier = self.role.soldiers:get(old_soldier_id)
		if old_soldier then old_soldier:out_battle() end
		self.data.companion[pos] = 0
		self:changed("companion")
	end
	return true
end

function _M:set_embattle(em)
	self.data.em = em
end

function _M:wear_equipment(pos,item)
	if item:inuse() then return false end
	if not self:can_fill("battle",pos) then return false end
	local idx = itemConfig:get_equipment_position(item:get_pid())
	if not idx then return false end
	local list = self.data.equips[pos]
	if not list or not list[idx] then return false end
	
	if list[idx] ~= 0 and self.role then
		local olditem = self.role.depot:get(list[idx])
		if olditem then olditem:take_off() end
	end
	list[idx] = item:get_id()
	item:wear(pos)
	self:changed("equips")
	return true
end

function _M:take_off_equipment(pos,idx)
	local list = self.data.equips[pos]
	if not list or not list[idx] or list[idx] == 0 then return false end
	if self.role then
		local item = self.role.depot:get(list[idx])
		if item then item:take_off() end
	end
	list[idx] = 0
	self:changed("equips")
	return true	
end

function _M:on_level_up(level)
	local bchange = false
	for i,v in ipairs(self.data.companion) do
		if	v == -1 and armyConfig:can_unlock_companion(i,level) and not armyConfig:get_unlock_companion_cost(i) then
			self.data.companion[i] = 0
			bchange = true
		end
	end
	if bchange then self:changed("companion") end

	local bchangebattle = false
	for i,v in ipairs(self.data.battle) do
		if	v == -1 and armyConfig:can_unlock_battle(i,level) then
			self.data.battle[i] = 0
			bchangebattle = true
		end
	end
	if bchangebattle then self:changed("battle") end
end

function _M:is_equipment(pos,pos2,id)
	local list = self.data.equips[pos]
	if not list or not list[pos2] or list[pos2] == 0 then return false end
	return list[pos2] == id
end

function _M:get_equipment_list_by_pos(pos)
	local equips ={}
	for i=3,6 do
		table_insert(equips, self.data.equips[pos][i])
	end
	return equips
end

function _M:get_full_army()
	if not self.army or self.fp_changed then
		local army = {}
		local commander_data = self.role.commanders:get(self.data.commander)
		if not commander_data then return false end
		local commander = commander_data:get_full_attributes()
		--ngx.log(ngx.ERR,"role.id:",self.role:get_id()," commander:",cjson.encode(commander) )
		local relation = armyConfig:get_relation_attributes(self.data)
		--ngx.log(ngx.ERR,"relation:",cjson.encode(relation) )

		local last = {
			base = {},
			rate = {}
		}
		for n,v in pairs(commander.base) do
			last.base[n] = (last.base[n] or 0) + v
		end
		for n,v in pairs(relation.base) do
			last.base[n] = (last.base[n] or 0) + v
		end
		for n,v in pairs(commander.rate) do
			last.rate[n] = (last.base[n] or 0) + v
		end
		for n,v in pairs(relation.rate) do
			last.rate[n] = (last.base[n] or 0) + v
		end
		
		for i,v in ipairs(self.data.battle) do
			if v > 0 then
				local soldier = self.role.soldiers:get(v)
				if soldier then
					local attrs = soldier:get_full_attributes()
					for _,e in ipairs(self.data.equips[i]) do
						local equip = self.role.depot:get(e)
						if equip then
							local eattrs = equip:get_full_attributes()
							for name,num in pairs(eattrs) do
								attrs[name] = (attrs[name] or 0) + num
							end
						end
					end
					for name,num in pairs(last.base) do
						attrs[name] = (attrs[name] or 0) + num
					end
					for name,num in pairs(last.rate) do
						if attrs[name] then attrs[name] = attrs[name] * (1+num/10000) end
					end
					
					army[v] = attrs
				end
			end
		end
		
		---全队属性
		local tv = {[1] = 0,[2] = 0,[3] = 0,}
		for i,v in pairs(army) do
			for k = 4,6 do
				if v[k] then tv[k-3] = tv[k-3] + v[k] end
				v[k] = nil
			end
		end
		
		for i,v in pairs(army) do
			for k = 1,3 do
				v[k] = (v[k] or 0) + tv[k]
			end
		end
		
		self.army = army
	end
	return self.army
end

function _M:get_fight_point()
	if not self.fp or self.fp_changed then
		local army = self:get_full_army()
		if army then
			self.fp = 0
			for _,v in pairs(army) do
				self.fp = self.fp + v[1]/8 + v[2]*2 + v[3]
			end
			self.fp = int(self.fp)
		end
	end
	return self.fp
end



function _M:get_depot_strengthen_great_lev()
	local lev = 10000
	for pos,v in ipairs(self.data.equips) do
		local strengthen_min = 10000
		local find = true
		for i=3,6 do
			if v[i] <= 0 then
				find = false
				break 
			end
			local item = self.role.depot:get(v[i])
			if item then
				if strengthen_min > item:get_strong_lev() then strengthen_min = item:get_strong_lev() end
			end
		end
		if find and lev > int(strengthen_min /10) then lev = int(strengthen_min /10) end
	end
	if lev == 10000 then return 0 end
	return lev
end

function _M:get_depot_refine_great_lev()
	local lev = 10000
	for pos,v in ipairs(self.data.equips) do
		local strengthen_min = 10000
		local find = true
		for i=3,6 do
			if v[i] <= 0 then
				find = false
				break 
			end
			local item = self.role.depot:get(v[i])
			if item then
				if strengthen_min > item:get_refine_lev() then strengthen_min = item:get_refine_lev() end
			end
		end
		if find and lev > int(strengthen_min /10) then lev = int(strengthen_min /10) end
	end
	if lev == 10000 then return 0 end
	return lev
end


function _M:get_all_min_strengthen()
	local strengthen_min = 10000
	for pos,v in ipairs(self.data.equips) do
		local find = true
		for i=3,6 do
			local item = self.role.depot:get(v[i])
			if item then
				if strengthen_min > item:get_strong_lev() then strengthen_min = item:get_strong_lev() end
			end
		end
	end
	if strengthen_min == 10000 then return 0 end
	return  strengthen_min
end

function _M:get_all_min_refine()
	local strengthen_min = 10000
	for pos,v in ipairs(self.data.equips) do
		for i=3,6 do
			local item = self.role.depot:get(v[i])
			if item then
				if strengthen_min > item:get_refine_lev() then strengthen_min = item:get_refine_lev() end
			end
		end
	end
	if strengthen_min == 10000 then return 0 end
	return strengthen_min
end

function _M:get_item_num( )
	local num = 0
	for pos,v in ipairs(self.data.equips) do
		for i=3,6 do
			local item = self.role.depot:get(v[i])
			if item then num = num + 1 end
		end
	end
	return num
end

function _M:get_soldiers()
	local num = 0
	for i,v in ipairs(self.data.battle) do
		if v >0 then num = num + 1 end
	end
	return num
end


return _M