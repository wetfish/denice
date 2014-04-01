dickbutt_table = {}

function dickbutt_callback(event, origin, params)
	local msg_parts = str_split_max(params[2], " ",2)
	if msg_parts[1] == "!dickbutt" then
		if dickbutt_table[origin] == nil or dickbutt_table[origin] < os.time() - 60 then
			for line in io.lines("lua/dickbutt.txt") do
				irc_msg(params[1], line:gsub(" +$",""))
			end
			dickbutt_table[origin] = os.time()
		else
			irc_msg(params[1], origin.." is a dickbutt! (wait "..(60-(os.time()-dickbutt_table[origin])).." seconds)")
		end
	end
end
register_callback("CHANNEL", "dickbutt_callback")
