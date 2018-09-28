-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local roleMgr = require "manager.roleMgr"
local CMail = require "game.model.role.mail"
local config = require "game.config"
local itemConfig = require "game.template.item"

local _M = function(role,data)
	if not data.recid or type(data.content) ~= "string" or #data.content < 3 then return 2 end
	if type(data.recid) == "string" then
		data.recid = roleMgr:get_role_id(data.recid)
		if not data.recid then return 1101 end
	end
	data.recid = tonumber(data.recid)
	local rec_num = 1
	local rec_roles = {}
	if data.recid <= 0 then
		
	else
		if data.recid == role:get_id() then return 1102 end
		local recrole = roleMgr:get_role(data.recid)
		if not recrole then return 1101 end
		rec_roles[1] = recrole
	end
	
	if #rec_roles == 0 then return 1101 end
	
	local e = role:check_resource_num(data.profit)
	if not e then return 100 end
	
	local mail = {
		t = 2,
		s = role:get_id(),
		h = data.title or "",
		c = data.content,
		p = profit,
	}
	
	local suc = 0
	local fail = nil
	for i,rec in ipairs(rec_roles) do
		if rec:receive_mail(CMail:new(nil,mail)) then
			role:consume_resource(cost)
			suc = suc + 1
		else
			fail = fail or {}
			table.insert(fail,rec:get_name())
		end
	end
	
	return 0,{data = {suc=suc,fail=fail}}
end

return _M