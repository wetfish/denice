-- test for one callback on multiple events
function message_callback(event, origin, params)
	my_master = get_config("bot:master")
	msg_parts = str_split(params[2], " ", 2)
	
	-- send to channel if channel message, reply to sender if privmsg
	send_to = params[1]
	if event == "PRIVMSG" then
		send_to = origin
	end
	
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
		elseif msg_parts[1] == "!testsql" then
			local result = sql_query_fetch("SELECT * FROM `test`")
			for rowi,rowv in pairs(result) do
				irc_msg(send_to, "Message "..rowv.Index..": "..rowv.String)
			end
		end
	end
end
register_callback("PRIVMSG", "message_callback")
register_callback("CHANNEL", "message_callback")

-- test for error handling
function error_callback(event, origin, params)
	my_master = get_config("bot:master")
	irc_msg(my_master, "ERROR EVENT:")
	-- error messages may have multiple lines
	for i,v in pairs(str_split(params[1], "\n")) do
		irc_msg(my_master, " > "..v)
	end
end
register_callback("ERROR", "error_callback")

-- test for multiple callbacks on one event
function join_channels(event, origin, params)
	irc_join("#test")
end
function connect_callback(event, origin, params)
	print("Now connected to "..origin)
end
register_callback("CONNECT", "join_channels")
register_callback("CONNECT", "connect_callback")

-- callback for user joining a channel
function join_callback(event, origin, params)
	my_name = get_config("bot:nick")
	if origin == my_name then
		print("Now in channel "..origin)
		irc_msg(params[1], "Hello all")
	else
		irc_msg(params[1], "Hello "..origin)
	end
end
register_callback("JOIN", "join_callback")




-- split function borrowed from http://lua-users.org/wiki/SplitJoin
function str_split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end
