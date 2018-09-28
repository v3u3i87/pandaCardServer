-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local CItem = require "game.model.role.item"
local task_config = require "game.template.task"
local item_config = require "game.template.item"

local cjson = require "include.cjson"

----不能叠加 .装备
local _M = model:extends()
_M.class = "role.depot"
_M.push_name  = "depot"
_M.changed_name_in_role = "depot"

_M.is_list = true
_M.child_model = CItem
_M.is_key_num = true


function _M:__up_version()
	_M.super.__up_version(self)
	self:get_depot_num()
end



function _M:gain(item)
	if not item or item.class ~= "item" then return false end
	self.max_id = self.max_id + 1
	_M.super.append(self,self.max_id,item)
	self:add_depot_num(item.data.p)
	return self.max_id
end

function _M:consume(id)
	local item = self.data[id]
	if not item then return false end
	self.data[id]:consume()
	_M.super.remove(self,id)
	self:remove_depot_num(id)
	return item
end

function _M:get_items(pid,strong_lev,refine_lev)
	local items = {}
	local num = 0
	for id,item in pairs(self.data) do
		if item:get_pid() == pid and item:get_user_id() == 0 then
			if (not strong_lev or strong_lev == item:get_strong_lev()) and (not refine_lev or refine_lev == item:get_refine_lev()) then
				num = num + 1
				items[id] = item
			end
		end
	end
	
	return num,items
end

function _M:get_num(params)
	if not params or #params == 0 then return self.child_num end
	local n = 0
	for i,v in pairs(self.data) do
		if item_config:get_type(v.data.p) == item_config.type.accessory then
			if task_config:check_condition(self.role,params,v.data.p) then n = n + 1 end
		end
	end
	return n
end

function _M:get_max_strengthen(params)
	local ms = 0
	if not params or #params == 0 then
		for id,item in pairs(self.data) do
			local s = item:get_strong_lev()
			if s > ms then ms = s end
		end
	else
		ms = self:get_num(params)
	end
	return ms

end

function _M:get_max_refine(params)
	local mr = 0
	if not params or #params == 0 then
		for id,item in pairs(self.data) do
			local r = item:get_refine_lev()
			if r > mr then mr = r end
		end
	else
		ms = self:get_num(params)
	end
	return mr
end

function _M:get_soldiers_pos(p)
	local pos = 1
	for id,item in pairs(self.data) do
		if p == item.data.p then
			pos = item.data.u
			break
		end
	end
	return pos
end

function _M:gain_more(profit)
	for id,item in pairs(profit) do
		self:gain(item)
	end
end

function _M:consume_more(cost)
	for id,item in pairs(cost) do
		self:consume(id)
	end
end

function _M:reborn(id)
	local item = self:get(id)
	if not item then return false end
	if not self:check_depot_full(nil,id) then return 602 end

	local profit = item:reborn()
	if self.role and profit then
		self.role:gain_resource(profit)
	end

	return profit
end

function _M:reclaim(id)
	local item = self:get(id)
	if not item then return false end
	local profit = item:reclaim()
	if self.role and profit then
		self.role:gain_resource(profit)
	end
	if profit then
		self:consume(id)
	end
	self:remove_depot_num(id)

	return profit
end

function _M:get_depot_num()
	if not self.equipment_num or not self.accessory_num then
		self.equipment_num = 0
		self.accessory_num = 0
		for id,item in pairs(self.data) do
			if item.data.u == 0 then
				local typ = item_config:get_type(item.data.p)
				if typ == item_config.type.equipment then	self.equipment_num = self.equipment_num +1
				elseif typ == item_config.type.accessory then item_config.type.accessory = item_config.type.accessory +1
				end
			end
		end
	end
	return self.equipment_num,self.accessory_num
end

function _M:check_depot_full(typ,id)
	if id then typ = item_config:get_type(id) end
	self:get_depot_num()
	if typ == item_config.type.equipment and self.equipment_num >= item_config.depot_equipment_max_num then return false
	elseif typ == item_config.type.accessory and self.accessory_num >= item_config.depot_accessory_max_num then return false 
	end
	return true
end

function _M:remove_depot_num(id)
	local typ = item_config:get_type(id)
	if typ == item_config.type.equipment then self.equipment_num = self.equipment_num -1
	elseif typ == item_config.type.accessory then self.accessory_num = self.accessory_num -1
	end
end

function _M:add_depot_num(id)
	local typ = item_config:get_type(id)
	if typ == item_config.type.equipment then self.equipment_num = self.equipment_num +1
	elseif typ == item_config.type.accessory then self.accessory_num = self.accessory_num +1
	end
end

return _M