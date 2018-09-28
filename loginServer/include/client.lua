local class = require "include.class"

local _M = class();

_M.client_type = {
	http = 0,
	socket = 1,
	websocket = 2,
}

function _M:init(typ,timeout,max_len,callfun,connect,push)
	self.type = typ
	self.timeout = timeout or 5000
	self.max_len = max_len or 65535
	self.msg = {}
	self.rec = false
	self.client = nil
	self.connect = connect
	local server
	if self.type == self.client_type.websocket then
		server = require "resty.websocket.server"
	elseif self.type == self.client_type.socket then
		server = require "include.socket"
	else
		server = require "include.http"
	end
	
	self.client, self.err = server:new{
		timeout = timeout,
		max_payload_len = max_len,
	}
	
	if not self.client then return false,self.err end
	if not callfun then 
		self.rec = true
		return true 
	end
	local ok,err = self:run(callfun,push)
	if self.client then self.client:send_close() end
	return ok,err
end

function _M:push_thread_run()
	while true do
		local msg = table.remove(self.msg,1)
		while msg do
			if msg.typ == "close" then
				if self.client then
					self.client:send_close(msg.content)
				end
				return
			end
			self:send(msg.content,msg.typ)
			msg = table.remove(self.msg,1)
		end
		
		ngx.sleep(0.1)
	end	
end

function _M:run(callfun,push)
	if not self.client then return false end
	if push then
		ngx.thread.spawn(self.push_thread_run,self)
	end
	
	while true do
		self.rec = false
		local data, typ, err = self.client:recv_frame()
		self.rec = true
		if self.client.fatal then return false,err end
		if not data then
			local bytes, err = self.client:send_ping()
			if not bytes then return false,err end
		elseif typ == "close" then
			return true
		elseif typ == "ping" then
			local bytes, err = self.client:send_pong()
			if not bytes then return false,err end
		elseif typ == "pong" then
			
		elseif typ == "text" or typ == "binary" then
			if self.connect then
				callfun(self.connect,data,typ)
			else
				callfun(data,typ)
			end
		end
	end
	
	return true
end

function _M:send(content,typ)
	if not self.client or self.client.fatal then return false; end
	if not typ then typ = type(content)	end
	local bytes, err = nil,""
	if typ == "string" or typ == "number" then
		bytes,err = self.client:send_text(content)
	else
		bytes,err = self.client:send_binary(content)
	end
	if not bytes then
		return false,err
	else
		return true
	end
end

function _M:push(content,typ)
	if self.rec then
		self:send(content,typ)
	else
		table.insert(self.msg,{content=content,typ=typ})
	end
end

function _M:close(code)
	if not code then code = 1000 end
	if not self.rec then
		table.insert(self.msg,{typ="close",content=code})
	else
		if self.client then
			self.client:send_close(code)
		end
	end
end

return _M