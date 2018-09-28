-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local swapHashKV = require "include.swaphashkv"
local rankMgr = require "manager.rankMgr"
local roleMgr = require "manager.roleMgr"
local config = require "game.config"
local open_config = require "game.template.open"

local _M = function(role,data)
	--if not data.id or type(data.id) ~= "number" then return 2 end
	--if not data.b or type(data.b) ~= "number" then return 2 end
	--if not data.e or type(data.e) ~= "number" then return 2 end
	if not data.id then return 2 end
	data.b = data.b or 1
	data.e = data.e or 20
	if not open_config:check_level(role,open_config.need_level.rank) then return 101 end

	local rank = rankMgr:get(data.id)
	if not rank then return 1801 end
	local r,ids
	if data.id == config.rank_type.arena then
		r = role:get_arena()
		ids = rank:get_objs_from_pt_range(data.b,data.e)

		ids = swapHashKV(ids,"ar")
		for i,v in pairs(ids) do
			v.ranking = i
		end
	else
		r = rank:get_obj_ranking(role.id,true)

		ids = rank:get_range_objs(data.b,data.e)
	end	
	return 0,{data=ids,my=r,id=data.id}
end
return _M
