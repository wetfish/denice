function seen_callback(event,origin,params)
	local p = str_split(params[2], " ")
	if p[1] == "!seen" then
		seen(p[2], origin, params[1])
	end
end
register_callback("CHANNEL","seen_callback")

function seen(message,user,channel)
        local row = sql_query_fetch("SELECT `timestamp`,`message`,`event`,`location` FROM `seen` WHERE `nick`='"..sql_escape(message).."'")
	local str
        if #row < 1 then
                irc_msg(channel,user..": I haven't seen "..message..".")
                return
        end
	
	if row[1].event == "CHANNEL" then
		str = "saying '"..row[1].message.."' in "..row[1].location
	elseif row[1].event == "PART" then
		str = "parting "..row[1].location
	elseif row[1].event == "QUIT" then
		str = "quitting with message '"..row[1].message.."'"
	elseif row[1].event == "JOIN" then
		str = "joining '"..row[1].location.."'"
	end

        irc_msg(channel,user..": I last saw "..message.." on "..os.date("%c",row[1].timestamp)..", "..(str or "UNDEFINED")..".")
end

function seen_parse(event, origin, params)
        sql_fquery("INSERT INTO `seen` (`nick`,`timestamp`,`event`,`location`,`message`) "..
                 "VALUES ('"..sql_escape(origin).."','"..os.time().."','"..sql_escape(event).."','"..sql_escape(params[1] or "").."','"..sql_escape(params[2] or "").."') ON DUPLICATE KEY UPDATE "..
                 "`timestamp`='"..os.time().."',`message`='"..sql_escape(params[2] or "").."',`event`='"..sql_escape(event).."',`location`='"..sql_escape(params[1] or "").."'")
end
register_callback("CHANNEL", "seen_parse")
register_callback("PART", "seen_parse")
register_callback("JOIN", "seen_parse")
register_callback("QUIT", "seen_parse")
