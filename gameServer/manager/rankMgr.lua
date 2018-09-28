-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local CRank = require "include.rank"
local mysql = require "include.mysql"
local roleMgr = require "manager.roleMgr"

local _M = {}

_M.rank_list = {}

function _M:init(db_config,rank_config)
	if self.binit then return end
	self.db_config = db_config
	for k,v in pairs(rank_config) do
		self.rank_list[v.type or k] = CRank:new(k,v.asc)
		self:init_rank(v.type or k)
	end
	self.binit = true
end

function _M:init_rank(rank_type)
	local rank = self:get(rank_type)
	if not rank then return end
	local con = mysql:new(self.db_config.ip,self.db_config.port,self.db_config.user,self.db_config.pw,self.db_config.db)
	if not rank:load(con) then
		for i,id in ipairs(roleMgr:get_all_role_ids()) do
			local role = roleMgr:get_role(id)
			if role then
				local rank_info = role:get_rank_info(rank_type)
				if rank_info and rank_info.pt and rank_info.pt > 0 then
					rank:update(rank_info)
				end
			end
		end
	end
	con:close()
end

function _M:append_new_rank(type,asc)
	if not self.rank_list[type] then
		self.rank_list[type] = CRank:new(type,asc)
		self:init_rank(type)
	end
end

function _M:del_rank(type)
	self.rank_list[type] = nil
end

function _M:get(rank_type)
	return self.rank_list[rank_type]
end

function _M:clean()
    for i,v in pairs(self.rank_list) do
        if v:clean() then return; end
    end
end

function _M:save()
	local con = mysql:new(self.db_config.ip,self.db_config.port,self.db_config.user,self.db_config.pw,self.db_config.db)
    for i,v in pairs(self.rank_list) do
        v:save(con);
    end
	con:close()
end

function _M:append(rank_type,role)
	local rank = self.rank_list[rank_type]
	if not rank or not role or not role.get_rank_info then return false end
	return rank:update(role:get_rank_info(rank_type))
end

function _M:remove(rank_type,role_id)
	local rank = self.rank_list[rank_type]
	if not rank then return false end
	return rank:remove(role_id)
end

function _M:update(rank_type,role)
	local rank = self.rank_list[rank_type]
	if not rank or not role or not role.get_rank_info then return false end
	return rank:update(role:get_rank_info(rank_type))
end

return _M