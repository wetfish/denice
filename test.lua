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
		elseif msg_parts[1] == "!testsql" then
			local result = sql_query_fetch("SELECT * FROM `test`")
			for rowi,rowv in pairs(result) do
				for coli,colv in pairs(rowv) do
					print("result["..rowi.."]."..coli.." = "..colv)
				end
			end
		end
	end
end
register_callback("CHANNEL", "message_callback")

function connect_callback(event, origin, params)
	irc_join("#test")
end
register_callback("CONNECT", "connect_callback")

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
