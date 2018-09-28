-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local generalMgr = require "game.model.general"
local config = require "game.template.general"
local sconfig = require "game.template.soldier"

local _M = function(role,data)
	if not data.soldier_id then return 2 end
	local soldier = role.soldiers:get(data.soldier_id)
	if not  soldier then return 500 end
	if sconfig:get_armyquality(data.soldier_id) < sconfig.hero_armyquality.orange and soldier:get_mrank() == 0 then return 2501 end
	local pos = generalMgr:get_soldier_can_record_pos(data.soldier_id,role:get_id())
	if not pos then return 2500 end
	generalMgr:record(data.soldier_id,pos,role:get_id())
	local profit = config:get_record_reward(pos)
	role:gain_resource(profit)
	return 0,{data = generalMgr:get_soldier_info(data.soldier_id),profit=profit}
end

return _M
