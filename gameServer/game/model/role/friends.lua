-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local CFriend = require "game.model.role.friend"
local config = require "game.config" 
local roleMgr = require "manager.roleMgr"

local table_insert = table.insert
local _M = model:extends()
_M.class = "role.friends"
_M.push_name  = "friends"
_M.changed_name_in_role = "friends"

_M.is_list = true
_M.child_model = CFriend
_M.is_key_num = true

function _M:update_myinfo_tofriends()
	for id,friend in pairs(self.data) do
		local frole = roleMgr:get_role(id)
		if frole then
			local ff = frole.friends:get(self.id)
			if ff then
				ff:update()
			end
		end
	end
end

function _M:check_give_one(id)
	local list = {}
	local friend = self.data[id]
	if not friend or friend:is_give() then return false end
	table_insert(list, friend)
	return list
end

function _M:check_give_all()
	local list = {}
	for id,friend in pairs(self.data) do
		if friend and not friend:is_give() then table_insert(list, friend)	end
	end
	return list
end

function _M:set_give(list,count)
	local num = 0
	for id,friend in ipairs(list) do
		num = num + 1	
		if friend and not friend:is_give() then friend:set_give() end
		if num >= count then break end
	end
end

function _M:check_receive_one(id)
	local list = {}
	local friend = self.data[id]
	if not friend or friend:is_receive(friend) then return false end
	table_insert(list, friend)
	return list
end

function _M:check_receive_all()
	local list = {}
	for id,friend in pairs(self.data) do
		if friend and not friend:is_receive(friend) then table_insert(list, friend)
		end
	end
	return list
end

function _M:set_receive(list,value,count)
	local num = 0
	for id,friend in ipairs(list) do
		num = num + 1
		if friend then friend:set_receive(value) end
		if num >= count then break end
	end
end

function _M:give_to_receive(id)
	local friend = self.data[id]
	if friend then friend:set_receive(1) end
end

function _M:check_apply_one(id)
	local list = {}	
	local friend = self.data[id]
	if not friend or not friend:is_append()	 then return false end
	table_insert(list, friend )
	return list
end

function _M:check_apply_all()
	local list = {}
	for id,friend in pairs(self.data) do
		if friend and friend:is_append() then table_insert(list, friend) end
	end
	return list
end

function _M:set_apply_add(list)
	for i,friend in ipairs(list) do
		if friend then friend:make_firends() end
	end
end

function _M:set_apply_remove(list)
	for id,friend in ipairs(list) do
		if friend then self:remove(friend:get_id()) end
	end
end

function _M:check_blacklist_add_one(id)
	local list = {}	
	local friend = self.data[id]
	if not friend or not friend:is_friend() then return false end
	table_insert(list, friend)
	return list
end

function _M:check_blacklist_add_all()
	local list = {}
	for id,friend in pairs(self.data) do
		if friend and friend:is_friend() then table_insert(list, friend)
		end
	end
	return list
end

function _M:set_blacklist_add(list)
	for id,friend in ipairs(list) do
		if friend then friend:make_blacklist() end
	end
end

function _M:check_blacklist_remove_one(id)
	local list = {}	
	local friend = self.data[id]
	if not friend or not friend:is_blacklist() then return false end
	table_insert(list, friend)
	return list
end

function _M:check_blacklist_remove_all()
	local list = {}
	for id,friend in pairs(self.data) do
		if friend and friend:is_blacklist() then table_insert(list, friend)	end
	end
	return list
end

function _M:set_blacklist_remove(list)
	for id,friend in ipairs(list) do
		if friend then friend:make_firends() end
	end
end

function _M:is_friend(id)
	local friend = self.data[id]
	if not friend or not friend:is_friend() then return false end
	return true
end

function _M:get_all_role( )
	local role_list = {}
	for id,friend in pairs(self.data) do
		local frole = roleMgr:get_role(id)
		if frole then table_insert(role_list, frole) end
	end
	return role_list
end

return _M