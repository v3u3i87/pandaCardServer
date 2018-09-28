-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local CMail = require "game.model.role.mail"
local timetool = require "include.timetool"

local _M = model:extends()
_M.class = "role.mailbox"
_M.push_name  = "mailbox"
_M.changed_name_in_role = "mailbox"
_M.is_list = true
_M.child_model = CMail
_M.is_key_num = true

function _M:__up_version()
	_M.super.__up_version(self)
	self.min_receive_time = timetool:now()
	for id,mail in pairs(self.data) do
		local rt = mail:get_receive_time()
		if self.min_receive_time > rt then
			self.min_receive_time = rt
		end
	end
end

function _M:get_all_mail_ids()
	local ids = {}
	for id,mail in pairs(self.data) do
		ids[id] = 1
	end
	return ids
end

function _M:receive(mail)
	if not mail or mail.class ~= "mail" then return false end
	self.max_id = self.max_id + 1
	mail:set_receive_time(timetool:now())
	return self:append(self.max_id,mail)
end

function _M:update()
	local ct = timetool:now()
	local maxtime = 30*24*60*60
	if ct - self.min_receive_time < maxtime then return end
	self.min_receive_time = ct
	for id,mail in pairs(self.data) do
		local rt = mail:get_receive_time()
		if ct - rt > maxtime then
			self:remove(id)
		elseif rt < self.min_receive_time then
			self.min_receive_time = rt
		end
	end
end

function _M:receive_from_mailMgr()
	local mailMgr = require "manager.mailMgr"
	mailMgr:receive(self.role)

end

return _M