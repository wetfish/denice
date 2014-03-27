function connect_callback(event, origin, params)
	local chanlist = str_split(get_config("server:channels"), ",")
	print("Now connected to "..origin)
	for i,v in pairs(chanlist) do
		irc_join(v)
	end
end

register_callback("CONNECT", "connect_callback")
