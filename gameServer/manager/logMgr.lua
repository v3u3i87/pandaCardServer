-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local C_DB = require "include.db"

local _M = {}

function _M:init(db_config)
	self.db = C_DB:new(db_config)
end

function _M:append(rec)
	self.db:append(rec)
end

function _M:save()
	self.db:clean(true)
end

return _M