-- Main message handling callback
function message_callback(event, origin, params)
	my_master = get_config("bot:master")
	msg_parts = str_split(params[2], " ", 2)
	
	-- send to channel if channel message, reply to sender if privmsg
	send_to = params[1]
	if event == "PRIVMSG" then
		send_to = origin
	else
		-- reply to channel messages with probability from config
		if math.random(1, 100) < get_config("bot:talk_rate")*100 then
			talk(send_to)
		end
	end
	
	if msg_parts[1] == "!talk" then
		talk(send_to,nil,msg_parts[2])
	end
	
	-- admin commands
	if origin == my_master then
		if msg_parts[1] == "!part" and msg_parts[2] ~= nil then
			irc_msg(send_to, "ok :(")
			irc_part(msg_parts[2])
		elseif msg_parts[1] == "!join" and msg_parts[2] ~= nil then
			irc_join(msg_parts[2])
		elseif msg_parts[1] == "!quit" then
			irc_quit("bye bye")
		elseif msg_parts[1] == "!rehash" then
			irc_msg(send_to, "Rehashing...")
			if rehash() then
				irc_msg(send_to, "Success.")
			else
				irc_msg(send_to, "Rehash failed.")
			end
		elseif msg_parts[1] == "!opme" then
			irc_cmode(params[1], "+o "..my_master)
		end
	end
end

register_callback("PRIVMSG", "message_callback")
register_callback("CHANNEL", "message_callback")
