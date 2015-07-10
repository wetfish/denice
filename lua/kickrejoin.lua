function kick_callback(event, origin, params)
	if params[2] == get_config("bot:nick") then
		irc_join(params[1])
	end
end
register_callback("KICK", "kick_callback")
