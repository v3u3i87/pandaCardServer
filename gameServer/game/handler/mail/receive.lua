-- @Author:pandayu
-- @Version:1.0
-- @DateTime:2018-09-09
-- @Project:pandaCardServer CardGame
-- @Contact: QQ:815099602
local _M = function(role,data)
	if not data.id then return 2 end
	data.id = tonumber(data.id)
	local ids = {}
	if data.id == -1 then
		ids = role.mailbox:get_all_mail_ids()
	else
		ids[data.id] = 1
	end
	local profitall = {};
	for id,v in pairs(ids) do
		local mail = role.mailbox:get(id)
		if not mail then return 1100 end
		if mail:has_attachment() then
			local profit = mail:get_attachment()
			role:gain_resource(profit)
			mail:attachment()
			role.mailbox:remove(id)
			
			for id,v in pairs(profit) do
				if not profitall[id] then
					profitall[id] = v
				else
					profitall[id] = profitall[id] + v
				end
			end
		end
	end
	if profitall then role:push("resource.get",profitall) end
	
	return 0
end

return _M