function dickbutt_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!dickbutt" then
		for line in io.lines("lua/dickbutt.txt") do
			irc_msg(params[1], line:gsub(" +$",""))
		end
	end
end
register_callback("CHANNEL", "dickbutt_callback")
