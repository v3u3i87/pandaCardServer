-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local t_remove = table.remove
local t_insert = table.insert

local _M = {}
_M.idx = 1
_M.free_idx = {}
_M.wb = {}

function _M:pop_free_idx()
	local idx = t_remove(self.free_idx,1)
	if not idx then
		idx = self.idx
		self.idx = self.idx + 1
	end
	return idx
end

function _M:push_free_idx(idx)
	t_insert(self.free_idx,idx)
end

function _M:add(wb)
	local idx = self:pop_free_idx()
	self.wb[idx] = wb
	return idx
end

function _M:remove(idx)
	if not idx then return end
	self[idx] = nil
	self:push_free_idx(idx)
end

return _M