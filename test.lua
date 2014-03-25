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

function message_callback(event, origin, params)
	my_master = get_config("bot:master")
	msg_parts = str_split(params[2], " ", 2)
	
	if origin == my_master then
		if msg_parts[1] == "!part" then
			irc_msg(params[1], "ok :(")
			irc_part(params[1])
		elseif msg_parts[1] == "!join" then
			irc_join(msg_parts[2])
		elseif msg_parts[1] == "!quit" then
			irc_quit("bye bye")
		elseif msg_parts[1] == "!rehash" then
			irc_msg(params[1], "rehashing")
			rehash()
		end
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
