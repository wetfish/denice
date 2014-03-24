
function message_callback(event, origin, params)
	my_master = get_config("bot:master")
	if(params[2] == "gtfo bitch") then
		irc_msg(params[1], "ok :(")
		irc_part(params[1])
	end
end
register_callback("CHANNEL", "message_callback")

function connect_callback(event, origin, params)
	irc_join("#rawpussy")
end
register_callback("CONNECT", "connect_callback")

function join_callback(event, origin, params)
	my_name = get_config("bot:nick")
	if origin == my_name then
		print("Now in channel "..origin)
		irc_msg(params[1], "Hello fags")
	end
end
register_callback("JOIN", "join_callback")
