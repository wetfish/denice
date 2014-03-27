function connect_callback(event, origin, params)
	local chanlist = get_config("bot:chans")
	print("Now connected to "..origin)
	for i,v in pairs(str_split(chanlist,",")) do
		irc_join(v)
	end
end

register_callback("CONNECT", "connect_callback")
