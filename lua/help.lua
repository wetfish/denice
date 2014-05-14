function help_callback(event, origin, params)
	for line in io.lines("lua/help.txt") do
		-- ignore comments
		if line:sub(1,1) ~= "#" then
			irc_msg(origin, irc_color(line))
		end
	end
end
register_command("help", "help_callback")
