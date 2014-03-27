-- callback for user joining a channel
function join_callback(event, origin, params)
	my_name = get_config("bot:nick")
	if origin == my_name then
		print("Now in channel "..params[1]..".")
		irc_msg(params[1], "Hello all")
	else
		print(origin.." joined "..params[1]..".")
		irc_msg(params[1], "Hello "..origin)
	end
end
register_callback("JOIN", "join_callback")

