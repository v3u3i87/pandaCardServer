-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CDb = require "include.db"
local cjson = require "include.cjson"
local timetool = require "include.timetool"
local toIntHash = require "include.tointhash"
local swapHashKV = require "include.swaphashkv"
local t_insert = table.insert

local _M = {}
_M.mails = {}
_M.changed = {}

function _M:init(db_config,CMail,failuretime)
	self.db = CDb:new(db_config)
	self.CMail = CMail or require "include.mail"
	self.failuretime = failuretime or 30*24*3600
	local result = self.db:get_all_record()
	if not result then return false end
	local ct = timetool:now()
	for i=1,#result do
		if result[i].receivers and type(result[i].receivers) == "string" then
			result[i].receivers = cjson.decode(result[i].receivers)
		else
			result[i].receivers = {}
		end
		if type(result[i].need_receivers) == "string" then
			result[i].need_receivers = cjson.decode(result[i].need_receivers)
		else
			result[i].need_receivers = nil
		end
		if type(result[i].content) == "string" then
			result[i].content = cjson.decode(result[i].content)
		else
			result[i].content = nil
		end
		if ct < result[i].failuretime and result[i].need_receivers and result[i].receivers and result[i].content then
			result[i].receivers = toIntHash(result[i].receivers)
			result[i].recs_hash = swapHashKV(result[i].receivers)
			if not result[i].need_receivers.sendtogroup then
				result[i].need_receivers = toIntHash(result[i].need_receivers)
				result[i].needrecs_hash = swapHashKV(result[i].need_receivers)
			end
			self.mails[result[i].id] = result[i]
		end
	end
	return true
end

function _M:save()
	for i,v in pairs(self.changed) do
		self.db:update(v)
	end
	if not self.db:save() then return false end
	self.changed = {}
end

function _M:append(sender,need_receivers,receivers,content)
	local mail = {}
	mail.createtime = timetool:now()
	mail.failuretime = mail.createtime + self.failuretime
	mail.sender = sender or 0
	mail.need_receivers = need_receivers or {sendtogroup=0}
	mail.receivers = receivers or {}
	mail.content = content or {}
	mail.recs_hash = swapHashKV(mail.receivers)
	if not mail.need_receivers.sendtogroup then
		mail.needrecs_hash = swapHashKV(mail.need_receivers)
	end
	self.db:append(mail)
	self.mails[mail.id] = mail
end

function _M:receive(role)
	if not role then return end
	local ct = timetool:now()
	local rid = role:get_id()
	local rct = role:get_create_time()
	for id,mail in pairs(self.mails) do
		if mail.failuretime < ct then
			self.mails[id] = nil
		else
			if not mail.recs_hash[rid] and rct < mail.createtime and (role:is_in_mail_group(mail.need_receivers.sendtogroup) or mail.needrecs_hash[rid]) then
				role:receive_mail(self.CMail:new(nil,mail.content))
				mail.recs_hash[rid] = 1
				t_insert(mail.receivers,rid)
				self.changed[id] = mail
			end
		end
	end
end

function _M:send_mails(sender,typ,title,content,profit,rids)
	local roleMgr = require "manager.roleMgr"
	sender = sender or 0
	typ = typ or 1
	title = title or ""
	content = content or ""
	profit = profit or {}
	local mail = {}
	if not rids then rids = 0 end
	mail.need_receivers = rids
	local group = true
	if type(rids) ~= "table" then
		group = rids
		mail.need_receivers = {sendtogroup=rids}
		rids = roleMgr:get_all_role_ids()
	end
	mail.content = {
		t = typ,
		s = sender,
		h = title,
		c = content,
		p = profit,
	}
	mail.sender = sender or 0
	mail.receivers = {}
	for i,id in ipairs(rids) do
		local role = roleMgr:get_role_in_cache(id)
		if role and role:is_online() and role:is_in_mail_group(group) then
			role:receive_mail(self.CMail:new(nil,mail.content))
			t_insert(mail.receivers ,id)
		end
	end
	self:append(mail.sender,mail.need_receivers,mail.receivers,mail.content)
end

return _M