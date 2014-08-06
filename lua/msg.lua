-- Main message handling callback
function message_callback(event, origin, params)
	local my_master = get_config("bot:master")
	local my_nick = get_config("bot:nick")
	local msg_parts = str_split_max(params[2], " ", 2)
	
	-- send to channel if channel message, reply to sender if privmsg
	local send_to = params[1]
	if event == "PRIVMSG" then
		send_to = origin
	else
		-- reply to channel messages with probability from config
		if math.random(1, 100) < get_config("bot:talk_rate")*100 and not no_talk(send_to) then
			if math.random(1, 100) > 50 then
				talk(send_to, nil, get_recent_word(params[1]))
			else
				talk(send_to, nil, nil)
			end
		end
	end
	
	if msg_parts[1] == "!talk" then
		talk(send_to,nil,msg_parts[2])
	elseif msg_parts[1] == "!atalk" then
		talk(send_to, nil, get_recent_word(params[1]))
	elseif msg_parts[1]:sub(0,my_nick:len()) == my_nick and not no_talk(send_to) then
		local words = big_words(msg_parts[2], 5)
		words[#words+1] = origin
		talk(send_to, nil, words[math.random(1,#words)])
	end
	
	-- admin commands
	if origin == my_master then
		if msg_parts[1] == "!part" and msg_parts[2] ~= nil then
			irc_msg(send_to, "ok :(")
			irc_part(msg_parts[2])
		elseif msg_parts[1] == "!join" and msg_parts[2] ~= nil then
			irc_join(msg_parts[2])
		elseif msg_parts[1] == "!recent" then
			dump_recent_words(msg_parts[2] or params[1], send_to)
		elseif msg_parts[1] == "!talkdump" then
			local n = msg_parts[2]
			if n == nil then n = 5 end
			for i=0,n do
				talk(send_to)
			end
		elseif msg_parts[1] == "!clean" then
			local thresh = os.time() - 2 * 7 * 24 * 60 * 60;
			sql_fquery("DELETE FROM `dictionary` WHERE `DateAdded` < '"..thresh.."'")
			irc_msg(send_to, "Deleted "..sql_affected_rows().." old dictionary rows")
			sql_fquery("DELETE FROM `quotes` WHERE `Delete` = '1'")		
			irc_msg(send_to, "Deleted "..sql_affected_rows().." flagged quotes")
			sql_fquery("OPTIMIZE TABLE `dictionary`")
			irc_msg(send_to, "Optimized dictionary table")
			sql_fquery("OPTIMIZE TABLE `quotes`")
			irc_msg(send_to, "Optimized quotes table")
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
		elseif msg_parts[1] == "!hopme" then
			irc_cmode(params[1], "+h "..my_master)
		elseif msg_parts[1] == "!vme" then
			irc_cmode(params[1], "+v "..my_master)
		end
	end
end

register_callback("PRIVMSG", "message_callback")
register_callback("CHANNEL", "message_callback")
