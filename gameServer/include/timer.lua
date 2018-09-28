local class = require "include.class"
local timer = ngx.timer.at
local _M = class()

--delay:延迟执行时间，单位为秒
--interval:执行回调函数间隔，单位为秒
--repeatnum:执行回调函数次数，<=0时表示没有次数限制
--callfun：回调函数
--...：回调函数参数列表
function _M:__init(delay,interval,repeatnum,callfun,...)
	self.delay = delay
	self.interval = interval
	self.repeatnum = repeatnum
	self.callback = callfun
	self.args = {...}
	self.timer = nil
	self.status = 0
	self:play()
end

function _M:play()
	if not self.timer then
		self.timer = ngx.timer.at(0,
			function(p,timer)
				ngx.sleep(timer.delay)
				while timer.status > 0 do
					if timer.status == 1 then
						timer.callback(unpack(timer.args))
						if timer.repeatnum > 0 then
							timer.repeatnum = timer.repeatnum - 1
							if timer.repeatnum <= 0 then 
								timer:stop()
								break
							end
						end
					end
					ngx.sleep(timer.interval)
				end
			end,
		self)
	end
	self.status = 1
end

function _M:pause()
	self.status = 2
end

function _M:stop()
	self.status = 0
	self.timer = nil
end

return _M