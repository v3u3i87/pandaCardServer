-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local model = require "game.model.role_model"
local config = require "game.template.arena"
local timetool = require "include.timetool"


local _M = model:extends()
_M.class = "role.guid"
_M.push_name  = "guid"
_M.changed_name_in_role = "guid"
_M.attrs = {
	v = 1,
	nid = 1,
}

function _M:__up_version()
	_M.super.__up_version(self)
end

function _M:on_time_up()

end

function _M:update()

end

function _M:set_nid(value)
	self.data.nid = value
end

return _M