function help_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!help" then
		for line in io.lines("lua/help.txt") do
			-- ignore comments
			if line:sub(1,1) ~= "#" then
				irc_msg(origin, irc_color(line))
			end
		end
	end
end
register_callback("CHANNEL", "help_callback")
