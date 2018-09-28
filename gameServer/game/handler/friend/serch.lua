-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local rankMgr = require "manager.rankMgr"
local roleMgr = require "manager.roleMgr"
local config = require "game.config"
local open_config = require "game.template.open"

local random = math.random

local _M = function(role,data)

	if not open_config:check_level(role,open_config.need_level.friend) then return 101 end

	local rs = {}
	local rank = rankMgr:get(config.rank_type.level)
	local r = rank:get_obj_ranking(role.id)
	local ids = rank:get_range_ids(r-500,r+500)
	local c = 0
	while c < 10 do
		local idx = random(1,1000)
		local fid = ids[idx]
		if fid and not rs[fid] then
			if not role.friends:get(fid) then
				local fr = roleMgr:get_role(fid)
				if fr then
					rs[fid] = fr:get_simple_info()
					c = c + 1
				end
			end
		end
	end
	
	return 0,{data=rs}
end

return _M